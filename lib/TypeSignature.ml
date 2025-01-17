open Identifier
open Type
open TypeParameters

(** Represents the interface to a type: its name, list of type parameters, and
    universe. We use this as part of the semantic extraction process: to
    validate the definition of a type, we need to know about other types defined
    in the module. To break the circularity, we have a pass that extracts type
    signatures first, and then validates type structures against those
    signatures.  *)
type type_signature = TypeSignature of identifier * typarams * universe
