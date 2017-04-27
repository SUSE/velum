# Salt Job Callbacks

Completion of commands sent to Salt usually affect our Minion's and their
current state.  For example, when we send an "orchestrate" command (see
`Velum::Salt.orchestrate`) a number of states are applied (a highstate) and the
final result is that the Minions already assigned a role are actually setup for
that role. This is something we need to show on our UI and also something we
need to be aware of in order to perform other tasks (e.g. bring down a Minion).

For the rest of this document we will call one standalone action on a Minion as
"Action".  An example of an action is "Turn a Minion to the assigned
role". Although an action might include a number of salt commands (and salt
jobs) we will assume for now that there is one salt job that designates the
action's completeness. To better understand this lets use an example.

Lets assume we have 2 salt minions available and we want to "orchestrate"
them. This is done in 2 steps.  First we assign the roles of master and minion
to the 2 minions. Then we run the ochestrate method.  The first step will simply
set the `role` column of the minion. Another integer column called `highstate`
will contain the current state:

- `:not_applied`: salt orchestration has not been applied yet.
- `:pending`: salt orchestration is running.
- `:applied`: salt orchestration was applied successfully.
- `:failed`: salt orchestration failed.

When we run the orchestrate method a highstate will be triggered on all Minions.
We will monitor the highstate completion events and as soon as we get one, we
will update the "highstate" column of that minion. This way we know which
Minions have been setup, and whether they returned an error or not.

The SaltHandler for highstates will need to match based on the tag (matching
regex: %r{salt/job/\d+/ret/(.*)}) and the "fun" key in data (which should be
"state.highstate").
