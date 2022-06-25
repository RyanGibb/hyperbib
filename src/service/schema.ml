(*---------------------------------------------------------------------------
   Copyright (c) 2021 University of Bern. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open Hyperbib.Std
open Result.Syntax

type conf = string * string
let conf =
  let name = Col.v "name" Type.Text fst in
  let value = Col.v "value" Type.Text snd in
  let conf k v = k, v in
  let row = Row.(unit conf * name * value) in
  Table.v "conf" row

let version = 1
let tables =
  [ Table.V conf;
    Table.V Label.table;
    Table.V Person.table;
    Table.V Person.Label.table;
    Table.V Subject.table;
    Table.V Subject.Label.table;
    Table.V Subject.See_also.table;
    Table.V Container.table;
    Table.V Container.Label.table;
    Table.V Reference.table;
    Table.V Reference.Label.table;
    Table.V Reference.Contributor.table;
    Table.V Reference.Subject.table;
    Table.V Reference.Cites.table;
  ]

let v = Rel.Schema.v ~tables ()

(*---------------------------------------------------------------------------
   Copyright (c) 2021 University of Bern

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
