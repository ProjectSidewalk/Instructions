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


# Create required tables and import data. Todo. KH should create a sql dump to import. I think it's cleaner to separate all the SQL commands from this shell script.
# ogr2ogr -f "PostgreSQL" PG:"host=localhost dbname=sidewalk user=vagrant password=sidewalk" "/vagrant/simple.geojson" -nln sidewalk_edge -append


# DOESN'T WORK
sudo su -l postgres -c "psql sidewalk -c 'ALTER TABLE sidewalk.sidewalk_edge RENAME COLUMN ogc_fid TO sidewalk_edge_id'"

sudo su -l postgres -c "psql sidewalk -c 'CREATE SEQUENCE feature_types_type_id_seq'"
sudo su -l postgres -c "psql sidewalk -c \"
  CREATE TABLE sidewalk.feature_types
  (
    type_id integer NOT NULL DEFAULT nextval('feature_types_type_id_seq'::regclass),
    type_string character varying(150),
    CONSTRAINT feature_types_pkey PRIMARY KEY (type_id)
  )
  WITH (
    OIDS=FALSE
  );
  ALTER TABLE sidewalk.feature_types OWNER TO vagrant;
\""
sudo su -l postgres -c "psql sidewalk -c \"
  INSERT INTO feature_types (type_string) VALUES
    ('type_string'),
    ('construction');
\""

sudo su -l postgres -c "psql sidewalk -c 'CREATE SEQUENCE accessibility_features_feature_id_seq'"
sudo su -l postgres -c "psql sidewalk -c \"
  CREATE TABLE sidewalk.accessibility_feature
  (
    accessibility_feature_id integer NOT NULL DEFAULT nextval('accessibility_features_feature_id_seq'::regclass),
    feature_geometry geometry(Point,4326),
    feature_type integer,
    lng double precision,
    lat double precision,
    CONSTRAINT accessibility_features_pkey PRIMARY KEY (accessibility_feature_id),
    CONSTRAINT accessibility_feature_feature_type_fkey FOREIGN KEY (feature_type)
        REFERENCES sidewalk.feature_types (type_id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
  )
  WITH (
    OIDS=FALSE
  );
  ALTER TABLE sidewalk.accessibility_feature OWNER TO vagrant;
\""

# TODO: sidewalk_edge_accessibility_feature
sudo su -l postgres -c "psql sidewalk -c 'CREATE SEQUENCE sidewalk_edge_accessibility_f_sidewalk_edge_accessibility_f_seq'"
sudo su -l postgres -c "psql sidewalk -c \"
  CREATE TABLE sidewalk.sidewalk_edge_accessibility_feature
  (
    sidewalk_edge_accessibility_feature_id integer NOT NULL DEFAULT nextval('sidewalk_edge_accessibility_f_sidewalk_edge_accessibility_f_seq'::regclass),
    sidewalk_edge_id integer,
    accessibility_feature_id integer,
    CONSTRAINT sidewalk_edge_accessibility_feature_pkey PRIMARY KEY (sidewalk_edge_accessibility_feature_id),
    CONSTRAINT sidewalk_edge_accessibility_feature_accessibility_feature_id_fk FOREIGN KEY (accessibility_feature_id)
        REFERENCES sidewalk.accessibility_feature (accessibility_feature_id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
  )
  WITH (
    OIDS=FALSE
  );
  ALTER TABLE sidewalk.sidewalk_edge_accessibility_feature
    OWNER TO postgres;
\""

sudo su -l postgres -c "psql sidewalk -c \"
  CREATE TABLE sidewalk.elevation
  (
    lat double precision NOT NULL,
    \"long\" double precision NOT NULL,
    elevation double precision,
    CONSTRAINT elevation_pkey PRIMARY KEY (lat, long)
  )
  WITH (
    OIDS=FALSE
  );
  ALTER TABLE sidewalk.elevation
    OWNER TO postgres;

  CREATE INDEX combined_index
    ON sidewalk.elevation
    USING btree
    (lat, long);

  CREATE INDEX lat_index
    ON sidewalk.elevation
    USING btree
    (lat);

  CREATE INDEX lng_index
    ON sidewalk.elevation
    USING btree
    (long);
\""

#Define custom functions
sudo su -l postgres -c "psql sidewalk -c '
  CREATE OR REPLACE FUNCTION sidewalk.calculate_accessible_cost(integer)
    RETURNS double precision AS
  \$BODY\$WITH allcosts
       AS (SELECT num_curbramps AS count,
                  CASE
                    WHEN num_curbramps = 0 THEN 50 --If there are no curbramps, add 50 meters to the cost
                    WHEN num_curbramps > 3 THEN -10 --If there are more than 3 curbramps, subtract 10 meters from the cost
                    ELSE 0 --If there are only 1 or 2 curbramps, cost is not affected.
                  END AS costcontrib
           FROM   (SELECT Count(*) AS num_curbramps --Count how many curbramps are on this street segment
                   FROM   (SELECT sidewalk.accessibility_feature.accessibility_feature_id,
                                  feature_type,
                                  sidewalk_edge_id
                           FROM   sidewalk.accessibility_feature
                                  INNER JOIN sidewalk.sidewalk_edge_accessibility_feature
                                          ON
                  sidewalk.sidewalk_edge_accessibility_feature.accessibility_feature_id
                  =
                  sidewalk.accessibility_feature.accessibility_feature_id) AS foo
                   WHERE  sidewalk_edge_id = \$1
                          AND feature_type = 1) AS curbramps --feature_type corresponds to the feature_id in fature_types
           UNION
           SELECT num_construction AS count,
                  CASE
                    WHEN num_construction = 0 THEN -10 --If there is no construction, subtract 10m from the cost
                    WHEN num_construction > 0 THEN num_construction * 10000 --For each construction obstacle, add 10km to the cost (which is so high that the street segment will probably be avoided)
                    ELSE 0
                  END AS costcontrib
           FROM   (SELECT Count(*) AS num_construction --Count the number of construction obstacles on the street segment
                   FROM   (SELECT sidewalk.accessibility_feature.accessibility_feature_id,
                                  feature_type,
                                  sidewalk_edge_id
                           FROM   sidewalk.accessibility_feature
                                  INNER JOIN sidewalk.sidewalk_edge_accessibility_feature
                                          ON
                  sidewalk.sidewalk_edge_accessibility_feature.accessibility_feature_id
                  =
                  sidewalk.accessibility_feature.accessibility_feature_id) AS foo
                   WHERE  sidewalk_edge_id = \$1
                          AND feature_type = 2) AS construction --feature_type corresponds to the feature_id in feature_types
           UNION
           (SELECT St_length(St_transform(wkb_geometry, 3637)), --Finally, add the length of the segment (in meters) to the cost
                   St_length(St_transform(wkb_geometry, 3637)) as costcontrib
            FROM   sidewalk.sidewalk_edge AS distance_cost
            WHERE  sidewalk_edge_id = \$1))
  SELECT sum(costcontrib)
  FROM   allcosts; \$BODY\$
    LANGUAGE sql VOLATILE
    COST 100;
  ALTER FUNCTION sidewalk.calculate_accessible_cost(integer)
    OWNER TO postgres;
'";

# TODO: Ways does not exist
# Add topology
# sudo su -l postgres -c "psql sidewalk -c \"
#   ALTER TABLE ways ADD COLUMN \"source\" integer;
#   ALTER TABLE ways ADD COLUMN \"target\" integer;

#   SELECT pgr_createTopology('sidewalk_edge', 0.00001, 'wkb_geometry', 'sidewalk_edge_id');
# \"";

# Final setup of the Django app
# cd /vagrant/routing
# python manage.py makemigrations
# python manage.py migrate
