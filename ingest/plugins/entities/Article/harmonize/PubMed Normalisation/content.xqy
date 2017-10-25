xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

import module namespace es = "http://marklogic.com/entity-services"
  at "/MarkLogic/entity-services/entity-services.xqy";

declare option xdmp:mapping "false";

(:~
 : Create Content Plugin
 :
 : @param $id          - the identifier returned by the collector
 : @param $options     - a map containing options. Options are sent from Java
 :
 : @return - your transformed content
 :)
declare function plugin:create-content(
  $id as xs:string,
  $options as map:map) as map:map
{
  let $doc := fn:doc($id)
  let $source :=
    if ($doc/es:envelope) then
      $doc/es:envelope/es:instance/node()
    else if ($doc/instance) then
      $doc/instance
    else
      $doc
  return
    plugin:extract-instance-Article($source)
};

(:~
 : Creates a map:map instance from some source document.
 : @param $source-node  A document or node that contains
 :   data for populating a Article
 : @return A map:map instance with extracted data and
 :   metadata about the instance.
 :)
declare function plugin:extract-instance-Article(
    $source as node()?
) as map:map
{
  (: the original source documents :)
  let $attachments := $source

  let $journal-title as xs:string? := ($source/front/journal-meta/journal-title-group/journal-title)[1]
  let $article-title as xs:string? := ($source/front/article-meta/title-group/article-title)[1]
  let $d-o-i as xs:string? := $source/front/article-meta/article-id[@pub-id-type eq "doi"]

  (: return the in-memory instance :)
  (: using the XQuery 3.0 syntax... :)
  let $model := json:object()
  let $_ := (
    map:put($model, '$attachments', $attachments),
    map:put($model, '$type', 'Article'),
    map:put($model, '$version', '0.0.1'),
    es:optional($model, 'journal-title', $journal-title),
    es:optional($model, 'article-title-flat', $article-title),
    es:optional($model, 'doi', $d-o-i)
  )

  (: if you prefer the xquery 3.1 version with the => operator....
   : https://www.w3.org/TR/xquery-31/#id-arrow-operator
  let $model :=
    json:object()
      =>map:with('$attachments', $attachments)
      =>map:with('$type', 'Article')
      =>map:with('$version', '0.0.1')
      =>es:optional('Journal Title', $journal -title)
      =>es:optional('Article Title', $article -title)
      =>es:optional('DOI', $d-o-i)
  :)
  return
    $model
};

declare function plugin:make-reference-object(
  $type as xs:string,
  $ref as xs:string)
{
  let $o := json:object()
  let $_ := (
    map:put($o, '$type', $type),
    map:put($o, '$ref', $ref)
  )
  return
    $o
};