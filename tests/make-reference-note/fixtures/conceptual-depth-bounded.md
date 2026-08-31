# Conceptual depth in software design

Conceptual depth describes how much useful functionality a module provides
behind a small interface. A deep module may contain substantial implementation
complexity while exposing only a few operations that callers can understand.

The interface is shallow when it requires many operations without doing much
work. It is deep when the implementation absorbs complexity and the caller can
use the abstraction without knowing its internals.

The term is sometimes confused with code volume. Size alone does not make a
module deep; the relevant relationship is useful behavior per interface
complexity.
