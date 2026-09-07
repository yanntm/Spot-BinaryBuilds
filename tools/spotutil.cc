// spotutil: the two Spot computations ITS-Tools used to run through python
// scripts (autstates.py, senseclsl.py), as one static binary over the Spot
// C++ API. Output formats are those of the scripts, which ITS-Tools parses.
//
//   spotutil stutter-states FILE.hoa
//     Line 1: for each state of the automaton, 1 if the state is stutter
//     invariant (0 otherwise), space separated; the set is made forward
//     closed first when it is not. Then the automaton in HOA, transition
//     based ("t"), after that modification.
//
//   spotutil sensitivity FILE.hoa
//     Line 1: "#is_stutter,is_lengthening_ins,is_shortening_ins".
//     Line 2: three 0/1 flags: the language is insensitive to stuttering
//     (both), to lengthening (closure against the complement is empty), to
//     shortening (sl against the complement is empty).

#include <iostream>
#include <string>
#include <vector>

#include <spot/parseaut/public.hh>
#include <spot/twaalgos/complement.hh>
#include <spot/twaalgos/hoa.hh>
#include <spot/twaalgos/postproc.hh>
#include <spot/twaalgos/product.hh>
#include <spot/twaalgos/stutter.hh>
#include <spot/twa/bddprint.hh>

#include "CLI11.hpp"

namespace
{

spot::twa_graph_ptr load (const std::string &file)
{
  spot::parsed_aut_ptr pa = spot::parse_aut (file, spot::make_bdd_dict ());
  if (pa->format_errors (std::cerr) || pa->aborted) {
    std::cerr << "spotutil: cannot read " << file << std::endl;
    std::exit (2);
  }
  return pa->aut;
}

int stutterStates (const std::string &file)
{
  spot::twa_graph_ptr aut = load (file);
  std::vector<bool> si = spot::stutter_invariant_states (aut);
  if (spot::is_stutter_invariant_forward_closed (aut, si) != 0)
    si = spot::make_stutter_invariant_forward_closed_inplace (aut, si);
  for (size_t i = 0; i < si.size (); ++i) std::cout << (i ? " " : "") << (si[i] ? 1 : 0);
  std::cout << '\n';
  spot::print_hoa (std::cout, aut, "t");
  std::cout << '\n';
  return 0;
}

int sensitivity (const std::string &file)
{
  spot::twa_graph_ptr aut = load (file);
  spot::postprocessor pp;
  pp.set_type (spot::postprocessor::GeneralizedBuchi);
  spot::twa_graph_ptr neg = pp.run (spot::complement (aut));
  bool shortInv = spot::product (spot::closure (aut), neg)->is_empty ();
  bool lenInv = spot::product (spot::sl (aut), neg)->is_empty ();
  std::cout << "#is_stutter,is_lengthening_ins,is_shortening_ins\n"
      << ((shortInv && lenInv) ? 1 : 0) << ' ' << (lenInv ? 1 : 0) << ' ' << (shortInv ? 1 : 0) << '\n';
  return 0;
}

} // namespace

int main (int argc, char **argv)
{
  CLI::App app { "spotutil: stutter analyses of an automaton with Spot, for ITS-Tools" };
  app.require_subcommand (1);
  std::string file;
  CLI::App *st = app.add_subcommand ("stutter-states", "Stutter-invariant states (forward closed), then the automaton in HOA.");
  st->add_option ("file", file, "Automaton in HOA format")->required ()->check (CLI::ExistingFile);
  CLI::App *se = app.add_subcommand ("sensitivity", "Insensitivity to stuttering, lengthening and shortening.");
  se->add_option ("file", file, "Automaton in HOA format")->required ()->check (CLI::ExistingFile);
  CLI11_PARSE (app, argc, argv);
  if (st->parsed ()) return stutterStates (file);
  return sensitivity (file);
}
