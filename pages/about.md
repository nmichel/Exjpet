# Original motivation

Years ago I needed a way to be able to validate big Json documents retrieved from various external APIs, and to extract data from them.

I had to be sure that documents have some structural properties, i.e. they contain specific fields, sub-documents, values for defined keys, ...

I wanted to be able to gather information. For example, when requesting route information from Google direction API, I wanted to be able to get all path-points at once. 

And I wanted all the be done fast.

That why I wrote [:ejpet](`https://github.com/nmichel/ejpet`), a library that gives the developper a way to describe what properties a Json document should have, and what data must be gathered. The tool transforms such an expresssion into a tailor-made matching function at runtime.

\- Nicolas

# About Exjpet library

This library offers 2 main modules:
- [Exjpet](`Exjpet`)
- [Exjpet.Matcher](`Exjpet.Matcher`)

The former allows for native use of [:ejpet](`https://github.com/nmichel/ejpet`) in Elixir. The API is the same as he `erlang` version, so the documentation of [:ejpet](`https://github.com/nmichel/ejpet`) applies.

The latter uses Elixir metaprogramming abilities (and the modular nature of `:ejpet`) to allow creation of tailor-made matching modules at ... compile-time !

# Matching modules generation with `Exjpet.Matcher`

With [Exjpet.Matcher](`Exjpet.Matcher`) it is easy to write modules where function clauses are called depending on the JSON document. The state management is easier, each clause being responsible for a small part of the whole. If several clauses match a same document, they all will be called, in declaration order. Have a look at the example in the documentation to have a better grasp of want can bo done.

Thanks to the functional nature of Elixir, it is straightforward and easy to plug Json-matching modules into a data processing pipeline (e.g. websocket) : the tool makes no assumption about the state parameter, it can be what is needed for module purpose.
