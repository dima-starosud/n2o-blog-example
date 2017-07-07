-module(login).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("nitro/include/nitro.hrl").
-include_lib("records.hrl").

main() -> #dtl{file = "simpllogin", bindings = [{body, body()}]}.
body() -> [
  #textbox{id = name},
  #button{id = login, body = "Login", postback = login, source = [name]}
].

event(login) ->
  n2o_session:ensure_sid([], ?CTX, []),
  Name = binary_to_list(wf:q(name)),
  wf:info(?MODULE, "User: ~p~n", [Name]),
  wf:user(Name),
  wf:redirect("/");
event(Event) -> wf:info(?MODULE, "Unknown Event: ~p~n", [Event]).
