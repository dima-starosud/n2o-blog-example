-module(post).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("nitro/include/nitro.hrl").
-include_lib("records.hrl").

post_id() -> wf:to_integer(wf:q(<<"id">>)).

main() ->
  case kvs:get(post, post_id()) of
    {ok, Post} -> html(Post);
    _ -> wf:state(status, 404), "Post not found" end.

comments() ->
  case wf:user() of
    undefined -> #link{body = "Login to add comment", url = "/login"};
    _ -> [
      #textarea{id = comment, class = ["form-control"], rows = 3},
      #button{id = send, class = ["btn", "btn-default"], body = "Post comment", postback = comment, source = [comment]}
    ] end.

event(init) ->
  wf:reg({post, post_id()}),
  [event({client, Comment}) || Comment <- kvs:entries(kvs:get(feed, {post, post_id()}), comment, undefined)];

event(comment) ->
  Comment = #comment{id = kvs:next_id("comment", 1), author = wf:user(), feed_id = {post, post_id()}, text = wf:q(comment)},
  kvs:add(Comment),
  wf:send({post, post_id()}, {client, Comment});

event({client, Comment}) ->
  wf:insert_bottom(comments,
    #blockquote{body = [
      #p{body = wf:html_encode(Comment#comment.text)},
      #footer{body = wf:html_encode(Comment#comment.author)}
    ]}).

content(Post) ->
  #'div'{
    class = container,
    body = [
      #h1{body = [
        wf:html_encode(Post#post.title), #br{},
        #small{body = ["by ", wf:html_encode(Post#post.author)]}
      ]},

      #p{body = wf:html_encode(Post#post.text)},

      #h3{body = "Comments"},
      #'div'{id = comments},
      comments()
    ]}.


head(Title) ->
  #head{body = [
    #meta{charset = "utf-8"},
    #meta{http_equiv = "X-UA-Compatible", content = "IE=edge"},
    #meta{name = "viewport", content = "width=device-width, initial-scale=1"},
    #title{body = Title},
    #meta_link{
      href = "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css",
      rel = "stylesheet"},
    #style{body = ".container { max-width: 60em; }"}
  ]}.


scripts() -> [
  #script{body = nitro:script()},
  static_scripts(),
  #script{body = "protos = [ $bert, $client ]; N2O_start();"}
].


static_scripts() -> [
  #script{src = "/n2o/protocols/bert.js"},
  #script{src = "/n2o/protocols/client.js"},
  #script{src = "/n2o/protocols/nitrogen.js"},
  #script{src = "/n2o/validation.js"},
  #script{src = "/n2o/bullet.js"},
  #script{src = "/n2o/utf8.js"},
  #script{src = "/n2o/template.js"},
  #script{src = "/n2o/n2o.js"}
].


html(Post) ->
  #html{body = [
    head(wf:html_encode(Post#post.title)),
    #body{body = [content(Post), scripts()]}
  ]}.
