%%% ------------------------------------------------------------
%% @doc google_static_maps_api
%% @end
%%% ------------------------------------------------------------

-module(google_static_maps_api).

-export([staticmap/4, staticmap/3, staticmap/2, staticmap/1]).

-include("google_maps_api.hrl").
-include_lib("hackney/include/hackney_lib.hrl").

-define(STATICMAP_API, "https://maps.googleapis.com/maps/api/staticmap").

-type image_format() :: png | png8 | png32 | gif | jpg | jpg_baseline.
-type maptype() :: roadmap | satellite | terrain | hybrid.
-type location() :: iodata() | #coordinate{}.
-type predefined_size() :: tiny | mid | small.
-type predefined_color() :: black | brown | green | purple | yellow
			  | blue | gray | orange | red | white.
-type label() :: 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G' |
		 'H' | 'I' | 'J' | 'K' | 'L' | 'M' | 'N' |
		 'O' | 'P' | 'Q' | 'R' | 'S' | 'T' |
		 'U' | 'V' | 'W' | 'X' | 'Y' | 'Z' |
		 '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'.
-type rgb() :: {byte(), byte(), byte()}.
-type rgba() :: {byte(), byte(), byte(), byte()}.
-type rgb_color() :: predefined_color() | rgb().
-type rgba_color() :: rgb_color() | rgba().
-type marker_style() :: {size, predefined_size()} |
			{color, rgb_color()} |
			{label, label()}.
-type markers() :: {[marker_style()], [location()]} |
		   [location()].
-type path_style() :: {weight, non_neg_integer()} |
		      {color, rgba_color()} |
		      {fillcolor, rgba_color()} |
		      {geodesic, boolean()}.
-type path() :: {[path_style()], [location()]} |
		[location()].
-type language() :: string().
-type region() :: string().
-type feature() :: all |		    % (default) all features
		   administrative |	    % all administrative areas
		   'administrative.country' |	   % countries
		   'administrative.land_parcel' |  % land parcels
		   'administrative.locality' |	   % localities
		   'administrative.neighborhood' | % neighborhoods
		   'administrative.province' |	   % provinces
		   landscape |			   % all landscapes
		   'landscape.man_made' |	% man-made structures
		   'landscape.natural' |	% natural features
		   'landscape.natural.landcover' | % landcover features
		   'landscape.natural.terrain' |   % terrain features
		   poi |		      % all points of interest
		   'poi.attraction' |	      % tourist attractions
		   'poi.business' |	      % businesses
		   'poi.government' |	      % government buildings
		   'poi.medical' | % emergency services, including hospitals, pharmacies, police, doctors, and others
		   'poi.park' |    % parks
		   'poi.place_of_worship' | % places of worship, including churches, temples, mosques, and others
		   'poi.school' |	    % schools
		   'poi.sports_complex' |   % sports complexes
		   road |		    % all roads
		   'road.arterial' |	    % arterial roads
		   'road.highway' |	    % highways
		   'road.highway.controlled_access' | % highways with controlled access
		   'road.local' |		      % local roads
		   transit |	      % all transit stations and lines
		   'transit.line' |   % transit lines
		   'transit.station' |		% all transit stations
		   'transit.station.airport' |	% airports
		   'transit.station.bus' |	% bus stops
		   'transit.station.rail' |	% rail stations
		   water.			% bodies of water
-type element() :: all | % (default) all elements of the specified feature
		   geometry | % all geometric elements of the specified feature
		   'geometry.fill' | % only the fill of the feature's geometry
		   'geometry.stroke' | % only the stroke of the feature's geometry
		   labels | % the textual labels associated with the specified feature
		   'labels.icon' | % only the icon displayed within the feature's label
		   'labels.text' | % only the text of the label
		   'labels.text.fill' | % only the fill of the label. The fill of a label is typically rendered as a colored outline that surrounds the label text
		   'labels.text.stroke'. % only the stroke of the label's text
-type style_rule() :: {hue, rgb()} |
		      {lightness, float()} | 	% [-100, 100]
		      {saturation, float()} |	% [-100, 100]
		      {gamma, float()} |	% [0.01, 10.0]
		      {inverse_lightness, boolean()} |
		      {visibility, on | off |  simplified} |
		      {color, rgb()} |
		      {weight, non_neg_integer()}.
-type style() :: {feature(), element(), [style_rule()]} |
		 {feature(), [style_rule()]} |
		 {element(), [style_rule()]} |
		 [style_rule()].
-type parameter() :: {center, location()} |
		     {zoom, integer()} |
		     {size, {integer(), integer()}} |
		     {scale, integer()} |
		     {format, image_format()} |
		     {maptype, maptype()} |
		     {language, language()} |
		     {region, region()} |
		     {markers, markers()} |
		     {path, path()} |
		     {visible, [location()]} |
		     {style, [style()]}.

-spec staticmap([parameter()], string(), string(), list()) -> file:filename().
staticmap(Parameters, _Key, _Signature, Options) ->
    staticmap(Parameters, Options).

-spec staticmap([parameter()], string(), list()) -> file:filename().
staticmap(Parameters, _Key, Options) ->
    staticmap(Parameters, Options).

-spec staticmap([parameter()], list()) -> file:filename().
staticmap(Parameters, Options) ->
    URL = hackney_url:parse_url(?STATICMAP_API),
    Qs = build_query([], Parameters),
    {ok, 200, _ResponseHeaders, Ref} =
	hackney:get(URL#hackney_url{qs = hackney_url:qs(Qs)}, [], [], Options),
    {ok, Body} = hackney:body( Ref ),
    hashfs:save(Body, ".png").

-spec staticmap([parameter()]) -> file:filename().
staticmap(Parameters) ->
    staticmap(Parameters, []).

build_query(Qs, []) ->
    Qs;
build_query(Qs, [{center, Center}|Parameters]) ->
    build_query([{<<"center">>, to_binary( Center )} | Qs], Parameters);
build_query(Qs, [{zoom, Zoom}|Parameters]) ->
    build_query([{<<"zoom">>, hackney_bstr:to_binary( Zoom )} | Qs], Parameters);
build_query(Qs, [{size, {Width, Height}}|Parameters]) ->
    Size = hackney_bstr:to_binary( io_lib:format("~bx~b", [Width, Height]) ),
    build_query([{<<"size">>, hackney_bstr:to_binary( Size )} | Qs], Parameters);
build_query(Qs, [{scale, Scale}|Parameters]) ->
    build_query([{<<"scale">>, hackney_bstr:to_binary( Scale )} | Qs], Parameters);
build_query(Qs, [{maptype, Maptype}|Parameters]) ->
    case lists:member(Maptype, [roadmap, satellite, hybrid, terrain]) of
	true ->
	    build_query([{<<"maptype">>, hackney_bstr:to_binary( Maptype )} | Qs], Parameters)
    end;
build_query(Qs, [{markers, Markers}|Parameters]) ->
    build_query([{<<"markers">>, build_markers(Markers)} | Qs], Parameters);
build_query(Qs, [_Parameter|Parameters]) ->
    build_query(Qs, Parameters).

build_markers({ _Styles, Locations }) ->
    build_markers( Locations );
build_markers(Locations) ->
    hackney_bstr:to_binary( lists:join("|", [to_binary(L) || L <- Locations]) ).

to_binary(#coordinate{lat = Lat, lng = Lng}) ->
    hackney_bstr:to_binary( io_lib:format("~f,~f", [Lat, Lng]) );
to_binary(Address) ->
    hackney_bstr:to_binary( Address ).
