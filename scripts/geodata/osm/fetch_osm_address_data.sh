#!/usr/bin/env bash

: '
fetch_osm_address_data.sh
-------------------------

Shell script to download OSM map and derive inputs
for language detection and address parser training set
construction.

Usage: ./fetch_osm_address_data.sh out_dir
'

if [ "$#" -ge 1 ]; then
    OUT_DIR=$1
else
    OUT_DIR=`pwd`
fi

set -e

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RESOURCES_DIR=$THIS_DIR/../../../resources
ADMIN1_FILE=$RESOURCES_DIR/language/regional/adm1.tsv

# Check for osmfilter and osmconvert
if ! type -P osmfilter osmconvert > /dev/null; then
cat << EOF
ERROR: osmfilter and osmconvert are required

On Debian/Ubuntu:
sudo apt-get install osmctools

Or to compile:
wget -O - http://m.m.i24.cc/osmfilter.c |cc -x c - -O3 -o osmfilter
wget -O - http://m.m.i24.cc/osmconvert.c | cc -x c - -lz -O3 -o osmconvert
EOF
exit 127
fi

PREV_DIR=`pwd`

cd $OUT_DIR

# Download id as PBF
# TODO: currently uses single mirror, randomly choose one instead
echo "Started OSM download: `date`"

ID_PBF="indonesia-latest.osm.pbf"

wget --quiet http://download.geofabrik.de/asia/indonesia-latest.osm.pbf -O $OUT_DIR/$ID_PBF &

wait

echo "Converting to o5m: `date`"
ID_O5M="indonesia-latest.o5m"

# Needs to be in O5M for some of the subsequent steps to work whereas PBF is smaller for download
osmconvert $ID_PBF -o=$ID_O5M &

wait

rm $ID_PBF

VALID_AEROWAY_KEYS="aeroway=aerodrome"
VALID_AMENITY_KEYS="amenity=ambulance_station or amenity=animal_boarding or amenity=animal_shelter or amenity=arts_centre or amenity=auditorium or amenity=baby_hatch or amenity=bank or amenity=bar or amenity=bbq or amenity=biergarten or amenity=boathouse or amenity=boat_rental or amenity=boat_sharing or amenity=boat_storage or amenity=brothel or amenity=bureau_de_change or amenity=bus_station or amenity=cafe or amenity=car_rental or amenity=car_sharing or amenity=car_wash or amenity=casino or amenity=cemetery or amenity=charging_station or amenity=cinema or amenity=childcare or amenity=clinic or amenity=club or amenity=clock or amenity=college or amenity=community_center or amenity=community_centre or amenity=community_hall or amenity=concert_hall or amenity=conference_centre or amenity=courthouse or amenity=coworking_space or amenity=crematorium or amenity=crypt or amenity=culture_center or amenity=dancing_school or amenity=dentist or amenity=dive_centre or amenity=doctors or amenity=dojo or amenity=dormitory or amenity=driving_school or amenity=embassy or amenity=emergency_service or amenity=events_venue or amenity=exhibition_centre or amenity=fast_food or amenity=ferry_terminal or amenity=festival_grounds or amenity=fire_station or amenity=food_count or amenity=fountain or amenity=gambling or amenity=game_feeding or amenity=grave_yard or amenity=greenhouse or amenity=gym or amenity=hall or amenity=health_centre or amenity=hospice or amenity=hospital or amenity=hotel or amenity=hunting_stand or amenity=ice_cream or amenity=internet_cafe or amenity=kindergarten or amenity=kiosk or amenity=kneipp_water_cure or amenity=language_school or amenity=lavoir or amenity=library or amenity=love_hotel or amenity=market or amenity=marketplace or amenity=medical_centre or amenity=mobile_money_agent or amenity=monastery or amenity=money_transfer or amenity=mortuary or amenity=mountain_rescue or amenity=music_school or amenity=music_venue or amenity=nightclub or amenity=nursery or amenity=nursing_home or amenity=office or amenity=parish_hall or amenity=park or amenity=pharmacy or amenity=idarium or amenity=place_of_worship or amenity=police or amenity=post_office or amenity=preschool or amenity=prison or amenity=pub or amenity=public_bath or amenity=public_bookcase or amenity=public_building or amenity=public_facility or amenity=public_hall or amenity=public_market or amenity=ranger_station or amenity=refugee_housing or amenity=register_office or amenity=research_institute or amenity=rescue_station or amenity=residential or amenity=Residential or amenity=restaurant or amenity=retirement_home or amenity=sacco or amenity=sanitary_dump_station or amenity=sanitorium or amenity=sauna or amenity=school or amenity=shelter or amenity=shop or amenity=shopping or amenity=shower or amenity=ski_rental or amenity=ski_school or amenity=social_centre or amenity=social_club or amenity=social_facility or amenity=spa or amenity=stables or amenity=stripclub or amenity=studio or amenity=supermarket or amenity=swimming_pool or amenity=swingerclub or amenity=townhall or amenity=theatre or amenity=training or amenity=trolley_bay or amenity=university or amenity=vehicle_inspection or amenity=veterinary or amenity=village_hall or amenity=vivarium or amenity=waste_transfer_station or amenity=whirlpool or amenity=winery or amenity=youth_centre"
GENERIC_AMENITIES="amenity=atm or amenity=bench or amenity=bicycle_parking or amenity=bicycle_rental or amenity=bicycle_repair_station or amenity=compressed_air or amenity=drinking_water or amenity=emergency_phone or amenity=fire_hydrant or amenity=fuel or amenity=grit_bin or amenity=motorcycle_parking or amenity=parking or amenity=parking_space or amenity=post_box or amenity=reception_area or amenity=recycling or amenity=taxi or amenity=telephone or amenity=ticket_validator or amenity=toilets or amenity=vending_machine or amenity=waste_basket or amenity=waste_disposal or amenity=water_point or amenity=watering_place or amenity=wifi"

VALID_OFFICE_KEYS="office=accountant or office=administrative or office=administration or office=advertising_agency or office=architect or office=association or office=camping or office=charity or office=company or office=consulting or office=educational_institution or office=employment_agency or office=estate_agent or office=financial or office=forestry or office=foundation or office=government or office=insurance or office=it or office=lawyer or office=newspaper or office=ngo or office=notary or office=parish or office=physician or office=political_party or office=publisher or office=quango or office=real_estate_agent or office=realtor or office=register or office=religion or office=research or office=tax or office=tax_advisor or office=telecommunication or office=therapist or office=travel_agent or office=water_utility"
VALID_SHOP_KEYS="shop="
VALID_HISTORIC_KEYS="historic=archaeological_site or historic=castle or historic=fort or historic=memorial or historic=monument or historic=ruins or historic=tomb"
VALID_PLACE_KEYS="place=farm or place=isolated_dwelling or place=square"
VALID_TOURISM_KEYS="tourism=hotel or tourism=attraction or tourism=guest_house or tourism=museum or tourism=chalet or tourism=motel or tourism=hostel or tourism=alpine_hut or tourism=theme_park or tourism=zoo or tourism=apartment or tourism=wilderness_hut or tourism=gallery or tourism=bed_and_breakfast or tourism=hanami or tourism=wine_cellar or tourism=resort or tourism=aquarium or tourism=apartments or tourism=cabin or tourism=winery or tourism=hut"
VALID_LEISURE_KEYS="leisure=adult_gaming_centre or leisure=amusement_arcade or leisure=arena or leisure=bandstand or leisure=beach_resort or leisure=bbq or leisure=bird_hide or leisure=bowling_alley or leisure=casino or leisure=common or leisure=club or leisure=dance or leisure=dancing or leisure=disc_golf_course or leisure=dog_park or leisure=fishing or leisure=fitness_centre or leisure=gambling or leisure=garden or leisure=golf_course or leisure=hackerspace or leisure=horse_riding or leisure=hospital or leisure=hot_spring or leisure=ice_rink leisure=landscape_reserve or leisure=marina or leisure=maze or leisure=miniature_golf or leisure=nature_reserve or leisure=padding_pool or leisure=park or leisure=pitch or leisure=playground or leisure=recreation_ground or leisure=resort or leisure=sailing_club or leisure=sauna or leisure=social_club or leisure=sports_centre or leisure=stadium or leisure=summer_camp or leisure=swimming_pool or leisure=tanning_salon or leisure=track or leisure=trampoline_park or leisure=turkish_bath or leisure=video_arcade or leisure=water_park or leisure=wildlife_hide"
VALID_LANDUSE_KEYS="landuse=allotmenets or landuse=basin or landuse=cemetery or landuse=commercial or landuse=construction or landuse=farmland or landuse=forest or landuse=grass or landuse=greenhouse_horticulture or landuse=industrial or landuse=landfill or landuse=meadow or landuse=military or landuse=orchard or landuse=plant_nursery or landuse=port or landuse=quarry or landuse=recreation_ground or landuse=resevoir or landuse=residential or landuse=retail or landuse=village_green or landuse=vineyard"

VALID_VENUE_KEYS="( ( $VALID_AEROWAY_KEYS ) or ( $VALID_AMENITY_KEYS ) or ( $VALID_HISTORIC_KEYS ) or ( $VALID_OFFICE_KEYS ) or ( $VALID_PLACE_KEYS ) or ( $VALID_SHOP_KEYS ) or ( $VALID_TOURISM_KEYS ) or ( $VALID_LEISURE_KEYS ) or ( $VALID_LANDUSE_KEYS ) )"

# Address data set for use in parser, language detection
echo "Filtering for records with address tags: `date`"
ID_ADDRESSES_O5M="id-addresses.o5m"
VALID_ADDRESSES_ID="( ( ( name= or addr:housename= ) and ( ( building= and building!=yes )  or $VALID_VENUE_KEYS ) ) ) or ( ( addr:street= or addr:place= ) and ( name= or building= or building:levels= or addr:housename= or addr:housenumber= ) )"
osmfilter $ID_O5M --keep="$VALID_ADDRESSES_ID" --drop-author --drop-version -o=$ID_ADDRESSES_O5M &

wait

ID_ADDRESSES_LATLONS="id-addresses-latlons.o5m"
osmconvert $ID_ADDRESSES_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_ADDRESSES_LATLONS &

wait

rm $ID_ADDRESSES_O5M
ID_ADDRESSES="id-addresses.osm"
osmfilter $ID_ADDRESSES_LATLONS --keep="$VALID_ADDRESSES_ID" -o=$ID_ADDRESSES_O5M &

wait

osmconvert $ID_ADDRESSES_O5M -o=$ID_ADDRESSES

rm $ID_ADDRESSES_O5M

rm $ID_ADDRESSES_LATLONS

# Border data set for use in R-tree index/reverse geocoding, parsing, language detection
echo "Filtering for borders: `date`"
ID_COUNTRIES="id-countries.osm"
ID_BORDERS_O5M="id-borders.o5m"
ID_BORDERS="id-borders.osm"
ID_ADMIN_BORDERS_OSM="id-admin-borders.osm"

VALID_COUNTRY_KEYS="ISO3166-1:alpha2="
VALID_ADMIN1_KEYS="ISO3166-2="
ADMIN1_LANGUAGE_EXCEPTION_IDS=$(grep "osm" $ADMIN1_FILE | sed 's/^.*relation:\([0-9][0-9]*\).*$/@id=\1/' | xargs echo | sed 's/\s/ or /g')

VALID_ADMIN_BORDER_KEYS="boundary=administrative or boundary=town or boundary=city_limit or boundary=civil_parish or boundary=civil or boundary=ceremonial or boundary=postal_district or place=island or place=city or place=town or place=village or place=hamlet or place=municipality or place=settlement"

VALID_POPULATED_PLACE_KEYS="place=city or place=town or place=village or place=hamlet or placement=municipality or place=locality or place=settlement or place=census-designated or place:ph=village"
VALID_NEIGHBORHOOD_KEYS="place=neighbourhood or place=neighborhood or place:ph=barangay"
VALID_EXTENDED_NEIGHBORHOOD_KEYS="place=neighbourhood or place=neighborhood or place=suburb or place=quarter or place=borough or place:ph=barangay"

VALID_LOCALITY_KEYS="place=city or place=town or place=village or place=hamlet or placement=municipality or place=neighbourhood or place=neighborhood or place=suburb or place=quarter or place=borough or place=locality or place=settlement or place=census-designated or place:ph=barangay or place:ph=village"

VALID_ADMIN_NODE_KEYS="place=city or place=town or place=village or place=hamlet or placement=municipality or place=neighbourhood or place=neighborhood or place=suburb or place=quarter or place=borough or place=island or place=islet or place=county or place=region or place=state or place=subdistrict or place=township or place=archipelago or place=department or place=country or place=district or place=census-designated or place=ward or place=subward or place=province or place=peninsula or place=settlement or place=subregion"

osmfilter $ID_O5M --keep="$VALID_ADMIN_BORDER_KEYS" --drop-author --drop-version -o=$ID_ADMIN_BORDERS_OSM &
osmfilter $ID_O5M --keep="$VALID_ADMIN_BORDER_KEYS or $VALID_LOCALITY_KEYS" --drop-author --drop-version -o=$ID_BORDERS_O5M &

wait

ID_ADMIN_NODES="id-admin-nodes.osm"
osmfilter $ID_O5M --keep="$VALID_ADMIN_NODE_KEYS" --drop-ways --drop-relations --ignore-dependencies --drop-author --drop-version -o=$ID_ADMIN_NODES
ID_BORDERS_LATLONS="id-borders-latlons.o5m"
osmconvert $ID_BORDERS_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_BORDERS_LATLONS
rm $ID_BORDERS_O5M
osmfilter $ID_BORDERS_LATLONS --keep="$VALID_ADMIN_BORDER_KEYS or $VALID_LOCALITY_KEYS" -o=$ID_BORDERS
rm $ID_BORDERS_LATLONS
osmfilter $ID_O5M --keep="$VALID_COUNTRY_KEYS or $VALID_ADMIN1_KEYS or $ADMIN1_LANGUAGE_EXCEPTION_IDS" --drop-author --drop-version -o=$ID_COUNTRIES

echo "Filtering for neighborhoods"
ID_LOCALITIES="id-localities.osm"
ID_NEIGHBORHOOD_BORDERS="id-neighborhood-borders.osm"

osmfilter $ID_O5M --keep="$VALID_NEIGHBORHOOD_KEYS" --drop-author --drop-version -o=$ID_NEIGHBORHOOD_BORDERS
osmfilter $ID_O5M --keep="name= and ( $VALID_LOCALITY_KEYS )" --drop-relations --drop-ways --ignore-dependencies --drop-author --drop-version -o=$ID_LOCALITIES

echo "Filtering for rail stations"
VALID_RAIL_STATION_KEYS="railway=station"
ID_RAILWAYS_O5M="id-rail-stations.o5m"
ID_RAILWAYS="id-rail-stations.osm"

osmfilter $ID_O5M --keep="$VALID_RAIL_STATION_KEYS" --drop-author --drop-version -o=$ID_RAILWAYS_O5M
ID_RAILWAYS_LATLONS="id-rail-stations-latlons.o5m"
osmconvert $ID_RAILWAYS_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_RAILWAYS_LATLONS
rm $ID_RAILWAYS_O5M
osmfilter $ID_RAILWAYS_LATLONS --keep="$VALID_RAIL_STATION_KEYS" -o=$ID_RAILWAYS
rm $ID_RAILWAYS_LATLONS

echo "Filtering for airports and terminals"
VALID_AIRPORT_KEYS="aeroway=aerodrome or aeroway=terminal"
ID_AIRPORTS_O5M="id-airports.o5m"
ID_AIRPORTS="id-airports.osm"

osmfilter $ID_O5M --keep="$VALID_AIRPORT_KEYS" --drop-author --drop-version -o=$ID_AIRPORTS_O5M
ID_AIRPORTS_LATLONS="id-airports-latlons.o5m"
osmconvert $ID_AIRPORTS_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_AIRPORTS_LATLONS
ID_AIRPORT_POLYGONS="id-airport-polygons.osm"
osmconvert $ID_AIRPORTS_O5M -o=$ID_AIRPORT_POLYGONS
rm $ID_AIRPORTS_O5M
osmfilter $ID_AIRPORTS_LATLONS --keep="$VALID_AIRPORT_KEYS" -o=$ID_AIRPORTS
rm $ID_AIRPORTS_LATLONS

echo "Filtering for subdivision polygons"
ID_SUBDIVISIONS="id-subdivisions.osm"
SUBDIVISION_AMENITY_TYPES="amenity=university or amentiy=college or amentiy=school or amentiy=hospital"
SUBDIVISION_LANDUSE_TYPES="landuse=residential or landuse=commercial or landuse=industrial or landuse=retail or landuse=military"
SUBDIVISION_PLACE_TYPES="place=allotmenets or place=city_block or place=block or place=plot or place=subdivision"
osmfilter $ID_O5M --keep="( $SUBDIVISION_AMENITY_TYPES or $SUBDIVISION_PLACE_TYPES or $SUBDIVISION_LANDUSE_TYPES )" --drop="( place= and not ( $SUBDIVISION_PLACE_TYPES ) ) or boundary=" --drop-author --drop-version -o=$ID_SUBDIVISIONS

echo "Filtering for postal_code polygons"
ID_POSTAL_CODES="id-postcodes.osm"
osmfilter $ID_O5M --keep="boundary=postal_code" --drop-author --drop-version -o=$ID_POSTAL_CODES


# Venue data set for use in venue classification
echo "Filtering for venue records: `date`"
ID_VENUES_O5M="id-venues.o5m"
osmfilter $ID_O5M --keep="( name=  and ( ( building= and building!=yes ) or $VALID_VENUE_KEYS or ( $VALID_RAIL_STATION_KEYS and addr:street= and ( wikipedia= or wikipedia:*= ) ) ) )" --drop-author --drop-version -o=$ID_VENUES_O5M
ID_VENUES_LATLONS="id-venues-latlons.o5m"
osmconvert $ID_VENUES_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_VENUES_LATLONS
rm $ID_VENUES_O5M
ID_VENUES="id-venues.osm"
osmfilter $ID_VENUES_LATLONS --keep="name= and ( ( building= and building!=yes ) or ( $VALID_VENUE_KEYS or ( $VALID_RAIL_STATION_KEYS and addr:street= and ( wikipedia= or wikipedia:*= ) ) ) )" -o=$ID_VENUES
rm $ID_VENUES_LATLONS

# Categories for building generic queries like "restaurants in Brooklyn"
echo "Filtering for buildings: `date`"
ID_BUILDINGS_O5M="id-buildings.o5m"
VALID_BUILDING_KEYS="building= or building:part="
VALID_BUILDINGS="( ( $VALID_BUILDING_KEYS ) and ( building!=yes or name= or addr:housename= or addr:street= or addr:housenumber= or addr:postcode= ) )"
osmfilter $ID_O5M --keep="$VALID_BUILDINGS" --drop-author --drop-version -o=$ID_BUILDINGS_O5M
ID_BUILDINGS_LATLONS="id-buildings-latlons.o5m"
osmconvert $ID_BUILDINGS_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_BUILDINGS_LATLONS
rm $ID_BUILDINGS_O5M
ID_BUILDINGS="id-buildings.osm"
osmfilter $ID_BUILDINGS_LATLONS --keep="$VALID_BUILDINGS" -o=$ID_BUILDINGS
rm $ID_BUILDINGS_LATLONS

echo "Filtering for building polygons: `date`"
ID_BUILDING_POLYGONS="id-building-polygons.osm"
osmfilter $ID_O5M --keep="( ( building= or building:part= or type=building ) and ( building:levels= or name= or addr:street= or addr:place= or addr:housename= or addr:housenumber= ) )" --drop-author --drop-version -o=$ID_BUILDING_POLYGONS


echo "Filtering for amenities: `date`"
ID_AMENITIES_O5M="id-amenities.o5m"
ALL_AMENITIES="aeroway= or amenity= or or emergency= or historic= or internet_access= or landuse= or leisure= or man_made= or mountain_pass= or office= or place= or railway= or shop= or tourism="
osmfilter $ID_O5M --keep="$ALL_AMENITIES" --drop-author --drop-version -o=$ID_AMENITIES_O5M
ID_AMENITIES_LATLONS="id-amenities-latlons.o5m"
osmconvert $ID_AMENITIES_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_AMENITIES_LATLONS
rm $ID_AMENITIES_O5M
ID_AMENITIES="id-amenities.osm"
osmfilter $ID_AMENITIES_LATLONS --keep="$ALL_AMENITIES" -o=$ID_AMENITIES
rm $ID_AMENITIES_LATLONS

echo "Filtering for natural: `date`"
ID_NATURAL_O5M="id-natural.o5m"
VALID_NATURAL_KEYS="natural="
osmfilter $ID_O5M --keep="$VALID_NATURAL_KEYS" --drop-author --drop-version -o=$ID_NATURAL_O5M
ID_NATURAL_LATLONS="id-natural-latlons.o5m"
osmconvert $ID_NATURAL_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_NATURAL_LATLONS
rm $ID_NATURAL_O5M
ID_NATURAL="id-natural.osm"
osmfilter $ID_NATURAL_LATLONS --keep="$VALID_NATURAL_KEYS" -o=$ID_NATURAL
rm $ID_NATURAL_LATLONS

echo "Filtering for waterways: `date`"
ID_WATERWAYS_O5M="id-waterways.o5m"
VALID_WATERWAY_KEYS="waterway="
osmfilter $ID_O5M --keep="$VALID_WATERWAY_KEYS" --drop-author --drop-version -o=$ID_WATERWAYS_O5M
ID_WATERWAYS_LATLONS="id-waterways-latlons.o5m"
osmconvert $ID_WATERWAYS_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_WATERWAYS_LATLONS
rm $ID_WATERWAYS_O5M
ID_WATERWAYS="id-waterways.osm"
osmfilter $ID_WATERWAYS_LATLONS --keep="$VALID_WATERWAY_KEYS" -o=$ID_WATERWAYS
rm $ID_WATERWAYS_LATLONS


# Streets data set for use in language classification 
echo "Filtering ways: `date`"
ID_WAYS_O5M="id-ways.o5m"
VALID_ROAD_TYPES="( highway=motorway or highway=motorway_link or highway=motorway_junction or highway=trunk or highway=trunk_link or highway=primary or highway=primary_link or highway=secondary or highway=secondary_link or highway=tertiary or highway=tertiary_link or highway=unclassified or highway=unclassified_link or highway=residential or highway=residential_link or highway=service or highway=service_link or highway=living_street or highway=pedestrian or highway=steps or highway=cycleway or highway=bridleway or highway=track or highway=road or ( highway=path and ( motorvehicle=yes or motorcar=yes ) ) )"
osmfilter id-latest.o5m --keep="name= and $VALID_ROAD_TYPES" --drop-relations --drop-author --drop-version -o=$ID_WAYS_O5M
ID_WAYS_NODES_LATLON="id-ways-nodes-latlons.o5m"
osmconvert $ID_WAYS_O5M --max-objects=1000000000 --all-to-nodes -o=$ID_WAYS_NODES_LATLON
# 10^15 is the offset used for ways and relations with --all-to-ndoes, extracts just the ways
ID_WAYS_LATLONS="id-ways-latlons.osm"
ID_WAYS="id-ways.osm"

osmfilter $ID_WAYS_NODES_LATLON --keep="name= and ( $VALID_ROAD_TYPES )" -o=$ID_WAYS
osmfilter $ID_WAYS_O5M --keep="name= and ( $VALID_ROAD_TYPES )" -o=$ID_WAYS_LATLONS
rm $ID_WAYS_NODES_LATLON
rm $ID_WAYS_O5M

rm $ID_O5M
rm $ID_O5M

echo "Completed : `date`"

cd $PREV_DIR
