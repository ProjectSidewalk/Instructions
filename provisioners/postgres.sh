#!/bin/sh -e

# Edit the following to change the name of the database user that will be created:
APP_DB_USER=vagrant
APP_DB_PASS=sidewalk

# Edit the following to change the name of the database that is created (defaults to the user name)
APP_DB_NAME=sidewalk

# Edit the following to change the version of PostgreSQL that is installed
PG_VERSION=9.3
POSTGIS_VERSION=2.1

###########################################################
# Changes below this line are probably not necessary
###########################################################
print_db_usage () {
  echo "Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: 5432)"
  echo "  Host: localhost"
  echo "  Port: 5432"
  echo "  Database: $APP_DB_NAME"
  echo "  Username: $APP_DB_USER"
  echo "  Password: $APP_DB_PASS"
  echo ""
  echo "Admin access to postgres user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo ""
  echo "psql access to app database user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME"
  echo ""
  echo "Env variable for application development:"
  echo "  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:5432/$APP_DB_NAME"
  echo ""
  echo "Local command to access the database via psql:"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 5432 $APP_DB_NAME"
}

export DEBIAN_FRONTEND=noninteractive

PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
  echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
  echo "To run system updates manually login via 'vagrant ssh' and run 'apt-get update && apt-get upgrade'"
  echo ""
  print_db_usage
  exit
fi

PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
  # Add PG apt repo:
  echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > "$PG_REPO_APT_SOURCE"

  # Add PGDG repo key:
  wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
fi

# Update package list and upgrade all packages
apt-get update
apt-get -y upgrade

# Install Postgres and PostGIS
apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"
apt-get -y install "postgresql-$PG_VERSION-postgis-$POSTGIS_VERSION"
# apt-get install -y postgis*
# apt-get install -y pgrouting*

PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main"

# Edit postgresql.conf to change listen address to '*':
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Append to pg_hba.conf to add password auth:
echo "host    all             all             all                     md5" >> "$PG_HBA"

# Explicitly set default client_encoding
echo "client_encoding = utf8" >> "$PG_CONF"

# Restart so that all new config is loaded:
service postgresql restart

# Setup pip
sudo apt-get install
sudo apt-get install -y postgresql-server-dev-9.3 python-dev python-pip
# sudo pip install -r /vagrant/requirements.txt

# Add pgRouting launchpad repository
sudo add-apt-repository ppa:georepublic/pgrouting
sudo apt-get update

# Install pgRouting packages
sudo apt-get install -y postgresql-9.4-pgrouting

# Install other required packages
sudo apt-get install -y gdal-bin

# Install required npm packages
# sudo apt-get install -y npm
# sudo npm install -g topojson

cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';

-- Create the database:
CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;

-- Give permisssions of the database to the new user:
GRANT ALL PRIVILEGES ON DATABASE $APP_DB_NAME to $APP_DB_USER; 

-- Create the user 'sidewalk'
CREATE ROLE sidewalk LOGIN;
ALTER USER sidewalk WITH PASSWORD 'sidewalk';
ALTER USER sidewalk SUPERUSER;
GRANT ALL PRIVILEGES ON DATABASE sidewalk TO sidewalk;

-- Create the schema 'sidewalk'
CREATE SCHEMA sidewalk;
GRANT ALL ON ALL TABLES IN SCHEMA sidewalk TO sidewalk;
ALTER DEFAULT PRIVILEGES IN SCHEMA sidewalk GRANT ALL ON TABLES TO sidewalk;
ALTER DEFAULT PRIVILEGES IN SCHEMA sidewalk GRANT ALL ON SEQUENCES TO sidewalk;

EOF

echo "Successfully created PostgreSQL dev virtual machine."
echo ""
print_db_usage

# Tag the provision time:
date > "$PROVISIONED_ON"

# --- Instructions below are not essential for setting up the database ---
# Following instructions from: https://github.com/tongning/access-route/blob/d49dc6efb6f49af7ed27baf633e9b0815778a4fc/README.md
# Repeated
# sudo su -l postgres -c "createdb sidewalk"

# Let us be superuser
sudo su -l postgres -c "psql sidewalk -c 'ALTER USER vagrant WITH SUPERUSER'"

# Install extentions
sudo su -l postgres -c "psql sidewalk -c 'CREATE EXTENSION postgis'"
sudo su -l postgres -c "psql sidewalk -c 'CREATE EXTENSION postgis_topology'"
sudo su -l postgres -c "psql sidewalk -c 'CREATE EXTENSION fuzzystrmatch'"
sudo su -l postgres -c "psql sidewalk -c 'CREATE EXTENSION postgis_tiger_geocoder'"

# DOESN'T WORK
sudo su -l postgres -c "psql sidewalk -c 'CREATE EXTENSION pgrouting'"