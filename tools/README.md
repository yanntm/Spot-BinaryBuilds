# `tools/` — spotutil, the Spot computations of ITS-Tools as one static binary

ITS-Tools used two python scripts in its Spot binaries plugin, `autstates.py`
and `senseclsl.py`, which `import spot`: wherever the python module is not
installed (the MCC cluster among others) they fail and the LTL engine loses
the analyses they carry. `spotutil` does both jobs over the Spot C++ API,
linked statically against the Spot this repository builds, and is deployed
beside `ltl2tgba`, `autfilt` and `ltlfilt`.

```
spotutil stutter-states FILE.hoa    # was autstates.py
spotutil sensitivity FILE.hoa       # was senseclsl.py
spotutil inf-stutter FILE.hoa       # was three Spot processes per state in computeInfStutter
```

* `stutter-states`: the stutter-invariant states of the automaton
  (`spot::stutter_invariant_states`), made forward closed in place when they
  are not (`make_stutter_invariant_forward_closed_inplace`); prints one line
  of space-separated 0/1 per state, then the automaton in HOA, transition
  based, as ITS-Tools' `SpotRunner.computeForwardClosedSI` reads it.
* `sensitivity`: whether the language is insensitive to lengthening
  (`closure(aut) x complement(aut)` empty), to shortening (`sl(aut) x
  complement(aut)` empty), and to stuttering (both); prints the header line
  `#is_stutter,is_lengthening_ins,is_shortening_ins` then the three flags, as
  `SpotRunner.analyzeCLSL` reads them.

* `inf-stutter`: for each state `q`, the letters `x` such that the word
  `x x x ...` is accepted from `q` (a one-state word automaton in product with
  the automaton read from `q`, an emptiness check per letter, at most 2^14
  letters else status 3 and the caller falls back); the answer is an HOA with
  the same states and atomic propositions where `q` carries one self-loop
  labelled by the disjunction of those letters, or no edge. ITS-Tools'
  `SpotRunner.computeInfStutter` used to run `autfilt --small` on the
  automaton restarted at each state, `ltl2tgba` on the stuttering formula
  and `autfilt --product-and` between them, three processes per state per
  formula.

Output formats are those of the scripts, byte for byte where ITS-Tools
parses them. Options are CLI11 (`CLI11.hpp`, vendored with its licence).

## Build

CMake, against the Spot install `build_spot.sh` leaves in
`install_dir/usr/local` (headers, `libspot.a`, `libbddx.a`):

```
cmake -S tools -B tools/build -DCMAKE_BUILD_TYPE=Release [-DSPOT_ROOT=/path/to/spot/prefix]
cmake --build tools/build
```

Built as C++20 (Spot 2.16 headers need it). Linked with `-static` on Linux (`-DSPOTUTIL_STATIC=OFF` to disable). The CI
runs this after `make install` and puts `spotutil` in `website/` with the
other binaries; ITS-Tools fetches it as `bin/spotutil-linux64`.
