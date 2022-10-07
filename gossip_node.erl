-module(gossip_node).
-export([start/3]).
-export([send_neighbor/4]).
-import(neighbor, [get_neighbor_list/4]).

loop_neighbor(_, 0, _, _, _) ->
    ok;
loop_neighbor(NeighborList, ListIndex, ParentPid, Rumor, RumorCount) ->
    Neighbor = lists:nth(ListIndex, NeighborList),
    master ! {self(), Neighbor},
    receive
        {NeighborPid} ->
            NeighborAlive = is_process_alive(NeighborPid),
            if (NeighborAlive) ->
                % io:fwrite("~p : Recived nightbor ~p from master which is ~p\n", [ParentPid, NeighborPid, NeighborAlive]),
                NeighborPid ! {Rumor};
            true ->
                ok
            end
    end,
    loop_neighbor(NeighborList, ListIndex-1, ParentPid, Rumor, RumorCount).


send_neighbor(NeighborList, ParentPid, Rumor, RumorCount) ->
    loop_neighbor(NeighborList, length(NeighborList), ParentPid, Rumor, RumorCount),
    send_neighbor(NeighborList, ParentPid, Rumor, RumorCount).

cur_state(10, _, _, _, _) ->
    io:fwrite("~p has got 10 messages, exiting with message ~p\n", [self(), "Fir se maa chudha"]),
    master ! {self()},
    ok;

cur_state(RumorCount, Index, NodeCount, Topology, SenderPid) ->
    receive
        {Rumor} ->
            io:fwrite("~p Recived rumour rumor count ~p\n", [self(), RumorCount]),
            NeighborList = get_neighbor_list(Index, Topology, NodeCount, []),
             % makeing it async

            if (RumorCount =/= 1) ->
                exit(SenderPid, ok);
            true ->
                ok
            end,
            NewSenderPid = spawn(gossip_node, send_neighbor, [NeighborList, self(), Rumor, RumorCount]),
            cur_state(RumorCount+1, Index, NodeCount, Topology, NewSenderPid)

    end.

start(Index, NodeCount, Topology) ->
    io:fwrite(" Started Gossip Node with pid ~p\n", [self()]),
    cur_state(1, Index, NodeCount, Topology, self()).