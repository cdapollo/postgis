-- polygon
WITH g AS (SELECT 'POLYGON((132 10,119 23,85 35,68 29,66 28,49 42,32 56,22 64,32 110,40 119,36 150,
57 158,75 171,92 182,114 184,132 186,146 178,176 184,179 162,184 141,190 122,
190 100,185 79,186 56,186 52,178 34,168 18,147 13,132 10))'::geometry As geom)
, gs AS (SELECT ST_Area(geom) As full_area, ST_Subdivide(geom,10) As geom FROM g)
SELECT '1' As rn, full_area::numeric(10,3) = SUM(ST_Area(gs.geom))::numeric(10,3), COUNT(gs.geom) As num_pieces, MAX(ST_NPoints(gs.geom)) As max_vert
FROM gs
GROUP BY gs.full_area;

-- linestring
WITH g AS (SELECT ST_Segmentize('LINESTRING(0 0, 10 10, 15 15)'::geography,150000)::geometry As geom)
, gs AS (SELECT ST_Length(geom) As m, ST_Subdivide(geom,8) As geom FROM g)
SELECT '2' As rn, m::numeric(10,3) = SUM(ST_Length(gs.geom))::numeric(10,3), COUNT(gs.geom) As num_pieces, MAX(ST_NPoints(gs.geom)) As max_vert
FROM gs
GROUP BY gs.m;

-- multipolygon
WITH g AS (SELECT 'POLYGON((132 10,119 23,85 35,68 29,66 28,49 42,32 56,22 64,32 110,40 119,36 150,
57 158,75 171,92 182,114 184,132 186,146 178,176 184,179 162,184 141,190 122,
190 100,185 79,186 56,186 52,178 34,168 18,147 13,132 10))'::geometry As geom)
, gs AS (SELECT ST_Area(ST_Union(g.geom, ST_Translate(g.geom,300,10) )) As full_area, ST_Subdivide(ST_Union(g.geom, ST_Translate(g.geom,300,10) ), 10) As geom FROM g)
SELECT '3' As rn, full_area::numeric(10,3) = SUM(ST_Area(gs.geom))::numeric(10,3), COUNT(gs.geom) As num_pieces, MAX(ST_NPoints(gs.geom)) As max_vert
FROM gs
GROUP BY gs.full_area;

SELECT '#3135', st_astext(ST_Subdivide(ST_GeomFromText('POLYGON((1 2,1 2,1 2,1 2))'), 2));
SELECT '#3522', ST_AsText(ST_Subdivide(ST_GeomFromText('POINT(1 1)',4326),10));

with inverted_geom as (
    select ST_Difference(
               ST_Expand('SRID=3857;POINT(0 0)' :: geometry, 20000000),
               ST_Buffer(
                   'SRID=3857;POINT(0 0)' :: geometry,
                   1,
                   1000
               )
           ) as geom
)
select '#3744', ST_Area(ST_Simplify(ST_Union(geom), 2))::numeric
from (
         select ST_Subdivide(geom) geom
         from inverted_geom
     ) z;

\i regress_big_polygon.sql

create table big_polygon_sliced as (
	select ST_Subdivide(geom) As geom FROM big_polygon
);

-- regression big polygon
SELECT '4' As rn,
	(select ST_Area(geom)::numeric(12,1) from big_polygon) as orig_area,
	SUM(ST_Area(gs.geom))::numeric(12,1) as pieces_area,
	COUNT(gs.geom) as num_pieces,
	MAX(ST_NPoints(gs.geom)) as max_vert
FROM big_polygon_sliced gs;

drop table big_polygon;
drop table big_polygon_sliced;
