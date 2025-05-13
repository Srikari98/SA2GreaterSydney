
CREATE MATERIALIZED VIEW sa2_stops_count AS
SELECT sa2.SA2_CODE21, COUNT(*) AS stop_count
FROM sa2_boundaries sa2
JOIN stops_data s
ON ST_Contains(sa2.geometry, ST_SetSRID(ST_MakePoint(s.stop_lon, s.stop_lat), 4283))
GROUP BY sa2.SA2_CODE21;


CREATE MATERIALIZED VIEW sa2_schools_count AS
SELECT sa2.SA2_CODE21, COUNT(*) AS school_count
FROM sa2_boundaries sa2
JOIN (
  SELECT * FROM catchments_primary
  UNION
  SELECT * FROM catchments_secondary
  UNION
  SELECT * FROM catchments_future
) AS schools
ON ST_Intersects(sa2.geometry, schools.geometry)
GROUP BY sa2.SA2_CODE21;


CREATE MATERIALIZED VIEW sa2_all_indicators AS
SELECT 
  b.SA2_CODE21,
  b.SA2_NAME21,
  b.SA4_NAME21,
  s.stop_count,
  sc.school_count,
  b.total_businesses AS business_count
FROM businesses_clean b
LEFT JOIN sa2_stops_count s USING(SA2_CODE21)
LEFT JOIN sa2_schools_count sc USING(SA2_CODE21);

CREATE MATERIALIZED VIEW sa2_z_scores AS
SELECT 
  SA2_CODE21,
  (stop_count - AVG(stop_count) OVER()) / STDDEV(stop_count) OVER() AS z_stop,
  (school_count - AVG(school_count) OVER()) / STDDEV(school_count) OVER() AS z_school,
  (business_count - AVG(business_count) OVER()) / STDDEV(business_count) OVER() AS z_business
FROM sa2_all_indicators;


CREATE MATERIALIZED VIEW sa2_score_sql AS
SELECT 
  SA2_CODE21,
  1 / (1 + EXP(-(z_stop + z_school + z_business))) AS score
FROM sa2_z_scores;
DROP MATERIALIZED VIEW IF EXISTS sa2_all_indicators CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sa2_schools_count CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sa2_stops_count CASCADE;

