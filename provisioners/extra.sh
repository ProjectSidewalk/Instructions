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
