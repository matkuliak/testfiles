#!/bin/bash
set -e

sudo -u postgres psql -c "CREATE ROLE sampledata WITH LOGIN PASSWORD 'sampledata';"
sudo -u postgres createdb --owner=sampledata sampledata

sudo -u postgres psql -c "CREATE TABLE public.airports ( \
  code character varying(3) NOT NULL, \
  name character varying(100) NOT NULL, \
  city character varying(50) NOT NULL, \
  country character varying(50) NOT NULL, \
  latitude double precision NOT NULL, \
  longitude double precision NOT NULL, \
  elevation integer NOT NULL \
); \
ALTER TABLE public.airports OWNER TO sampledata;" sampledata

sudo -u postgres psql -c "\copy airports FROM '/tmp/airports.csv' DELIMITER ',' CSV;" sampledata

sudo -u postgres psql -c "CREATE TABLE flights ( \
  year int, \
  month int, \
  day_of_month int, \
  day_of_week int, \
  dep_time  int, \
  crs_dep_time int, \
  arr_time int, \
  crs_arr_time int, \
  unique_carrier varchar(6), \
  flight_num int, \
  tail_num varchar(8), \
  actual_elapsed_time int, \
  crs_elapsed_time int, \
  air_time int, \
  arr_delay int, \
  dep_delay int, \
  origin varchar(3), \
  dest varchar(3), \
  distance int, \
  taxi_in int, \
  taxi_out int, \
  cancelled int, \
  cancellation_code varchar(1), \
  diverted varchar(1), \
  carrier_delay int, \
  weather_delay int, \
  nas_delay int, \
  security_delay int, \
  late_aircraft_delay int \
); \
ALTER TABLE public.flights OWNER TO sampledata;" sampledata

sudo -u postgres psql -c "\copy flights FROM '/tmp/flights.csv' DELIMITER ',' HEADER NULL 'NA' CSV;" sampledata

sudo -u postgres psql -c "ALTER TABLE flights ADD COLUMN dep_timestamp timestamp;" sampledata
sudo -u postgres psql -c "ALTER TABLE flights ADD COLUMN arr_timestamp timestamp;" sampledata
sudo -u postgres psql -c "CREATE INDEX dep_timestamp_idx ON flights (dep_timestamp);" sampledata
sudo -u postgres psql -c "CREATE INDEX arr_timestamp_idx ON flights (dep_timestamp);" sampledata
sudo -u postgres psql -c "CREATE INDEX origin_idx ON flights (origin);" sampledata
sudo -u postgres psql -c "CREATE INDEX dest_idx ON flights (dest);" sampledata
sudo -u postgres psql -c "CREATE INDEX unique_carrier_idx ON flights (unique_carrier);" sampledata

sudo -u postgres psql -c "UPDATE flights SET dep_timestamp = CONCAT(year,'-',LPAD(month::text, 2, '0'),'-',LPAD(day_of_month::text, 2, '0'),' ',LEFT(LPAD(dep_time::text, 4, '0'),2),':',RIGHT(LPAD(dep_time::text, 4, '0'),2))::timestamp" sampledata
sudo -u postgres psql -c "UPDATE flights SET arr_timestamp = UPDATE flights SET arr_timestamp=dep_timestamp + interval '1 minute' * (COALESCE(air_time, 0)+COALESCE(taxi_in, 0)+COALESCE(taxi_out, 0)) WHERE cancelled=0" sampledata
# Clean 1 record with invalid data
sudo -u postgres psql -c "UPDATE FLIGHTS SET cancelled=1 WHERE arr_timestamp-dep_timestamp < interval '1 minutes'" sampledata
