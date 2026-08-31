# Adaptive Split Gate

The Gate chooses the least burdensome route that still produces independently usable
understanding. It evaluates two axes: whether a unit is central to the user's inquiry,
and whether interpretation is routine or consequential/ambiguous.

| | Routine interpretation | Consequential/ambiguous |
|---|---|---|
| Inquiry-central | user reconstructs relation; agent drafts/verifies | user reconstructs; ambiguity discussed; agent verifies |
| Supporting/contextual | agent drafts/verifies | agent verifies; consult only for defensible-choice impact |

“User reconstructs” means the user supplies a semantic relation, not assent or a keyword
echo. Sufficient comprehension is an independently generated contrast, mechanism,
condition, reason, implication, qualification, or attribution relation. “Yes,” repeating
the source's nouns, and agreement with the agent's wording fail the Gate.

High-learning/low-risk units therefore require the user's semantic relation before the
agent drafts a Source Point. The agent may then draft and verify the source-owned wording.
Low-learning/high-risk units require source verification and preservation of posture,
scope, attribution, and uncertainty; the agent must not force the user to paraphrase
material that is not useful for the user's learning goal.

## Inquiry-map fields

Each unit assessment references a source-unit ID and may carry:

- `relevance`: central, supporting, or peripheral;
- `learning_relevance`: high, medium, or low;
- `interpretive_risk`: low, medium, or high;
- `comprehension`: untouched, emerging, sufficient, or unclear;
- `selection`: candidate, selected, verify, or leave;
- `disposition`: the chosen Gate route;
- `draft_state`: untouched, drafted, confirmed, parked, or verified.

These are transient observations, not facts about the source. Reassess them as the
conversation changes. A derived grounding frontier uses them to select the next move,
but is never persisted as an authoritative queue.
