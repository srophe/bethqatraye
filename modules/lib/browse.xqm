xquery version "3.1";
(:~  
 : Builds HTML browse pages for Srophe Collections and sub-collections 
 : Alphabetical English and Syriac Browse lists, browse by type, browse by date, map browse. 
 :)
module namespace browse="http://srophe.org/srophe/browse";

(:eXist templating module:)
import module namespace templates="http://exist-db.org/xquery/html-templating";

(: Import Srophe application modules. :)
import module namespace config="http://srophe.org/srophe/config" at "../config.xqm";
import module namespace data="http://srophe.org/srophe/data" at "data.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";
import module namespace sf="http://srophe.org/srophe/facets" at "facets.xql";
import module namespace global="http://srophe.org/srophe/global" at "lib/global.xqm";
import module namespace maps="http://srophe.org/srophe/maps" at "maps.xqm";
import module namespace page="http://srophe.org/srophe/page" at "paging.xqm";
import module namespace tei2html="http://srophe.org/srophe/tei2html" at "../content-negotiation/tei2html.xqm";

(: Namespaces :)
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace srophe="https://srophe.app";
declare namespace html="http://www.w3.org/1999/xhtml";

(: Global Variables :)
declare variable $browse:alpha-filter {request:get-parameter('alpha-filter', '')[1]};
declare variable $browse:lang {request:get-parameter('lang', '')[1]};
declare variable $browse:view {request:get-parameter('view', '')[1]};
declare variable $browse:perpage { 
    if(request:get-parameter('perpage', 20)[1]) then 
        if(request:get-parameter('perpage', 20)[1] castable as xs:integer) then request:get-parameter('perpage', 20)[1] cast as xs:integer
        else 20
    else 20
    };
declare variable $browse:start { 
    if(request:get-parameter('start', 1)[1]) then 
        if(request:get-parameter('start', 1)[1] castable as xs:integer) then request:get-parameter('start', 1)[1] cast as xs:integer
        else 1
    else 1
    }; 

(:~
 : Build initial browse results based on parameters
 : Calls data function data:get-records(collection as xs:string*, $element as xs:string?)
 : @param $collection collection name passed from html, should match data subdirectory name or tei series name
 : @param $element element used to filter browse results, passed from html
 : @param $facets facet xml file name, relative to collection directory
:)  
declare function browse:get-all($node as node(), $model as map(*), $collection as xs:string*, $element as xs:string?, $facets as xs:string?){
    let $data := if($browse:view = 'syriac' or $browse:lang = 'syr' or $browse:view = 'arabic' or $browse:lang = 'ar') then
                    data:get-records($collection, 'tei:place/tei:placeName')
                 else data:get-records($collection, $element)
    return 
        map{"hits" : $data}
};

(:
 : Main HTML display of browse results
 : @param $collection passed from html 
:)
declare function browse:show-hits($node as node(), $model as map(*), $collection, $sort-options as xs:string*, $facets as xs:string?){
  let $hits :=  $model("hits") 
  let $facet-config := global:facet-definition-file($collection)
  return 
    if($browse:view != '' and $browse:view != 'map') then
        <div class="col-md-12" xmlns="http://www.w3.org/1999/xhtml">
            <div class="float-container">
                <div class="{if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then "pull-left" else "pull-right paging"}">
                    {page:pages($hits, $collection, $browse:start, $browse:perpage,'', $sort-options)}
                </div>
                    {
                        if($browse:view = ('type','date','facets','other','ܐ-ܬ','ا-ي') ) then ()
                        else browse:browse-abc-menu()
                    }
           </div>
           <br/>
            <div class="row">
             {
                 if($facet-config != '') then
                    <div class="col-md-3">{sf:display($hits, $facet-config)}</div> 
                 else () 
                 }
             <div class="{if($facet-config != '') then 'col-md-9' else 'col-md-12'}">
                {(
                    if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else(),  
                    if($browse:alpha-filter != '') then  
                     <h3>{(
                        if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}, attribute lang {"syr"}, attribute class {"label pull-right"}) 
                        else attribute class {"label"},
                        $browse:alpha-filter)}</h3>
                    else (),
                    <div class="results {if($browse:lang = 'syr' or $browse:lang = 'ar') then 'syr-list' else 'en-list'}">
                        {if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}) else()}
                        {browse:display-hits($hits)}
                    </div>
                )}
              </div>
          </div> 
        </div>
    else 
        <div class="col-md-12 map-lg" xmlns="http://www.w3.org/1999/xhtml" id="browseMap">
            {let $geojson :=  if(request:get-parameter('fq', '') != '') then $hits[descendant::tei:geo]
                              else if(contains(request:get-query-string(), 'facet-')) then $hits[descendant::tei:geo]  
                             else doc(xmldb:encode-uri(concat($config:app-root,'/resources/lodHelpers/placeNames.xml')))//tei:place
             return                              
               (maps:build-map($geojson,count($hits)),
                <div id="map-filters" class="map-overlay">
                    <span class="filter-label">Filter Map 
                        <a class="pull-right small togglelink text-info" 
                        data-toggle="collapse" data-target="#filterMap" 
                        href="#filterMap" data-text-swap="- Hide"> + Show </a></span>
                    <div class="collapse" id="filterMap">
                        {sf:display($hits, $facet-config/descendant::facet:facets/facet:facet-definition[@label="Place Type"])}
                         {sf:display($hits, $facet-config/descendant::facet:facets/facet:facet-definition[@label="Location Type"])}
                         <!--
                        {facet:output-html-facets($geojson[descendant::tei:geo], $facet-config/descendant::facet:facets/facet:facet-definition[@name="Place Type"])}
                        {facet:output-html-facets($geojson[descendant::tei:geo], $facet-config/descendant::facet:facets/facet:facet-definition[@name="Location Type"])}-->
                    </div>
                </div>)}
        </div>
};

(:
 : Page through browse results
:)
declare function browse:display-hits($hits){
    for $hit in subsequence($hits, $browse:start,$browse:perpage)
    let $sort-title := 
        if($browse:lang != 'en' and $browse:lang != 'syr' and $browse:lang != '') then 
            <span class="sort-title" lang="{$browse:lang}" xml:lang="{$browse:lang}">
            {(if($browse:lang='ar') then attribute dir { "rtl" } else (), 
                if($browse:lang='ar') then ft:field($hit, "titleArabic")[matches(global:build-sort-string(., $browse:lang),global:get-alpha-filter())]
                else if($browse:lang != 'en') then 
                    tei2html:tei2html($hit/descendant::tei:placeName[@xml:lang = $browse:lang][matches(global:build-sort-string(., $browse:lang),global:get-alpha-filter())][1])
                else())}
            </span> 
        else ()
    let $uri := replace($hit/descendant::tei:publicationStmt/tei:idno[1],'/tei','')
    return 
        <div xmlns="http://www.w3.org/1999/xhtml" class="result">
            {($sort-title, tei2html:summary-view($hit[1], $browse:lang, $uri[1]))}
        </div>
};

(:
 : Display map from HTML page 
 : For place records map coordinates
 : For other records, check for place relationships
 : @param $collection passed from html 
:)
declare function browse:display-map($node as node(), $model as map(*), $collection, $sort-options as xs:string*){
    let $hits := $model("hits")
    return browse:get-map($hits)                    
};

(:~ 
 : Display maps for data with coordinates in tei:geo
 :)
declare function browse:get-map($hits as node()*){
    if($hits/descendant::tei:body/tei:listPlace/descendant::tei:geo) then 
            maps:build-map($hits[descendant::tei:geo], count($hits))
    else if($hits/descendant::tei:relation[contains(@passive,'/place/') or contains(@active,'/place/') or contains(@mutual,'/place/')]) then
        let $related := 
                for $r in $hits//tei:relation[contains(@passive,'/place/') or contains(@active,'/place/') or contains(@mutual,'/place/')]
                let $title := string($r/ancestor::tei:TEI/descendant::tei:title[1])
                let $rid := string($r/ancestor::tei:TEI/descendant::tei:idno[1])
                let $relation := string($r/@name)
                let $places := for $p in tokenize(string-join(($r/@passive,$r/@active,$r/@mutual),' '),' ')[contains(.,'/place/')] return <placeName xmlns="http://www.tei-c.org/ns/1.0">{$p}</placeName>
                return 
                    <record xmlns="http://www.tei-c.org/ns/1.0">
                        <title xmlns="http://www.tei-c.org/ns/1.0" name="{$relation}" id="{replace($rid,'/tei','')}">{$title}</title>
                            {$places}
                    </record>
        let $places := distinct-values($related/descendant::tei:placeName/text()) 
        let $locations := 
            for $id in $places
            for $geo in collection($config:data-root || '/places/tei')//tei:idno[. = $id][ancestor::tei:TEI[descendant::tei:geo]]
            let $title := if($geo/ancestor::tei:TEI/descendant::*[@srophe:tags="#headword"]) then $geo/ancestor::tei:TEI/descendant::*[@srophe:tags="#headword"][1] else $geo/ancestor::tei:TEI/descendant::*[@syriaca-tags="#syriaca-headword"][1]
            let $type := string($geo/ancestor::tei:TEI/descendant::tei:place/@type)
            let $geo := $geo/ancestor::tei:TEI/descendant::tei:geo
            return 
                <place xmlns="http://www.tei-c.org/ns/1.0">
                    <idno>{$id}</idno>
                    <title>{concat(normalize-space($title), ' - ', $type)}</title>
                    <desc>Related:
                    {
                        for $p in $related[child::tei:placeName[. = $id]]/tei:title
                        return concat('<br/><a href="',string($p/@id),'">',normalize-space($p),'</a>')
                    }
                    </desc>
                    <location>{$geo}</location>  
                </place>
        return 
            if(not(empty($locations))) then 
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <h3 class="panel-title">Related places</h3>
                    </div>
                    <div class="panel-body">
                        {maps:build-map($locations,count($places))}
                    </div>
                </div>
             else ()
    else ()
};

(:~
 : Browse Alphabetical Menus
 : Currently include Syriac, Arabic, Russian and English
 dir="rtl"
:)
declare function browse:browse-abc-menu(){
    <div class="browse-alpha tabbable" xmlns="http://www.w3.org/1999/xhtml">
        <ul class="list-inline" >
        {
            if(($browse:lang = 'syr')) then  
                (attribute dir {"rtl"},
                for $letter in tokenize('ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ', ' ')
                return 
                    if($letter = 'ALL') then 
                         <li class="syr-menu {if($browse:alpha-filter = $letter) then "selected badge" else()}" lang="en"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>                        
                    else <li class="syr-menu {if($browse:alpha-filter = $letter) then "selected badge" else()}" lang="syr"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
                    )
            else if(($browse:lang = 'ar')) then
                (attribute dir {"rtl"},
                for $letter in tokenize('ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي', ' ')
                return 
                    if($letter = 'ALL') then
                         <li class="ar-menu {if($browse:alpha-filter = $letter) then "selected badge" else()}" lang="en"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
                    else <li class="ar-menu {if($browse:alpha-filter = $letter) then "selected badge" else()}" lang="ar"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
                )                    
            else if($browse:lang = 'ru') then 
                for $letter in tokenize('А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я',' ')
                return 
                <li>{if($browse:alpha-filter = $letter) then attribute class {"selected badge"} else()}<a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>            
            else                
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z', ' ')
                return
                    <li>{if($browse:alpha-filter = $letter) then attribute class {"selected badge"} else()}<a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
        }
        <li class="{if($browse:lang = 'syr') then 'syr-menu' else if($browse:lang = 'ar') then 'ar-menu' else ()} {if($browse:alpha-filter = 'ALL') then "selected badge" else()}" lang="en"><a href="?lang={$browse:lang}&amp;alpha-filter=ALL{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', ''))  else()}">All Entries</a></li>
        </ul>
    </div>
};
(: Syriaca.org specific functions :)
declare function browse:by-type($hits, $collection, $sort-options){
    let $facet-config := global:facet-definition-file($collection)
    return         
    (<div class="col-md-4" xmlns="http://www.w3.org/1999/xhtml">
        {if($browse:view='type') then 
            if($collection = ('geo','places')) then 
                browse:browse-type($collection)
            else facet:output-html-facets($hits, $facet-config/descendant::facet:facets/facet:facet-definition[@name="Type"]) 
         else if($browse:view = 'date') then 
            facet:output-html-facets($hits, $facet-config/descendant::facet:facets/facet:facet-definition[@name="Century"])
         else facet:output-html-facets($hits, $facet-config/descendant::facet:facets/facet:facet-definition)         
        }</div>,
    <div class="col-md-8" xmlns="http://www.w3.org/1999/xhtml">{
        if($browse:view='type') then
            if(request:get-parameter('fq', '') and contains(request:get-parameter('fq', ''), 'fq-Type:') or request:get-parameter('type', '') != '') then
                (page:pages($hits, $collection, $browse:start, $browse:perpage,'', $sort-options),
                <h3>{concat(upper-case(substring(request:get-parameter('type', ''),1,1)),substring(request:get-parameter('type', ''),2))}</h3>,
                <div>{(        
                    <div class="col-md-12 map-md">{browse:get-map($hits)}</div>,
                        browse:display-hits($hits)
                    )}</div>)
            else <h3>Select Type</h3>
        else if($browse:view='date') then 
            if(request:get-parameter('fq', '') and contains(request:get-parameter('fq', ''), 'fq-Century:')) then 
                (page:pages($hits, $collection, $browse:start, $browse:perpage,'', $sort-options),
                <h3>{request:get-parameter('date', '')}</h3>,
                <div>{browse:display-hits($hits)}</div>)
            else <h3>Select Date</h3>  
       else (page:pages($hits, $collection, $browse:start, $browse:perpage,'', $sort-options),
            <h3>Results {concat(upper-case(substring(request:get-parameter('type', ''),1,1)),substring(request:get-parameter('type', ''),2))} ({count($hits)})</h3>,
            <div>{(
                <div class="col-md-12 map-md">{browse:get-map($hits)}</div>,
                browse:display-hits($hits)
                )}</div>)
    }</div>)       
};

(:~
 : Browse Type Menus
:)
declare function browse:browse-type($collection){  
    <ul class="nav nav-tabs nav-stacked" xmlns="http://www.w3.org/1999/xhtml">
        {
            if($collection = ('places','geo')) then 
                    for $types in collection($config:data-root || '/places/tei')//tei:place
                    let $type := lower-case($types/@type)
                    group by $place-types := $type
                    order by $place-types ascending
                    return
                        <li> {if(request:get-parameter('type', '') = replace(string($place-types),'#','')) then attribute class {'active'} else '' }
                            <a href="?view=type&amp;type={$place-types}">
                            {if(string($place-types) = '') then 
                                'unknown' 
                             else
                                let $label := replace(string($place-types),'#|-',' ')
                                return concat(upper-case(substring($label,1,1)),substring($label,2))}
                             <span class="count"> ({count($types)})</span>
                            </a> 
                        </li>
            else  ()
        }
    </ul>
};

declare function browse:large-map($node as node(), $model as map(*), $collection, $sort-options as xs:string*, $facets as xs:string?){
let $hits := if(request:get-parameter('fq', '')!= '') then 
                util:eval(concat("collection($config:data-root)//tei:TEI[descendant::tei:geo]",facet:facet-filter(global:facet-definition-file($collection))))
             else if(contains(request:get-query-string(), 'facet-')) then 
                collection($config:data-root)//tei:body[ft:query(., (),sf:facet-query())][descendant::tei:geo] 
             else if(request:get-query-string()) then 
                collection($config:data-root)//tei:body[ft:query(., (),sf:facet-query())][descendant::tei:geo]
             else doc(xmldb:encode-uri(concat($config:app-root,'/resources/lodHelpers/placeNames.xml')))//tei:place
let $facets :=  if(request:get-query-string()) then 
                    $hits
                else collection($config:data-root)//tei:body[ft:query(., (),sf:facet-query())][descendant::tei:geo]
let $facet-config := global:facet-definition-file($collection)
return 
<div xmlns="http://www.w3.org/1999/xhtml" id="browseMap">
    {maps:build-map($hits,count($hits))}
    <div id="map-filters" class="map-overlay">
        <span class="filter-label">Filter Map 
            <a class="pull-right small togglelink text-info" data-toggle="collapse" data-target="#filterMap" href="#filterMap" data-text-swap="- Hide"> + Show </a></span>
            <div class="collapse" id="filterMap">
                {sf:display($facets, $facet-config/descendant::facet:facets/facet:facet-definition[@label="Place Type"])}
                {sf:display($facets, $facet-config/descendant::facet:facets/facet:facet-definition[@label="Location Type"])}
            </div>
    </div>
</div>
};