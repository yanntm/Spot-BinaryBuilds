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
//
//   spotutil inf-stutter FILE.hoa
//     For each state q of the automaton, the letters x such that the word
//     x x x ... is accepted from q: an automaton in HOA with the same states
//     and atomic propositions, where state q carries one self-loop labelled
//     by the disjunction of those letters, or no edge when there is none
//     (ITS-Tools' computeInfStutter, which ran three Spot processes per state
//     for this: a simplification, the stuttering formula, their product).

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
#include <spot/twa/twagraph.hh>

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

/** Beyond this many atomic propositions the letters are too many to enumerate: status 3, the caller falls back. */
constexpr size_t MAX_APS = 14;

int infStutter (const std::string &file)
{
  spot::twa_graph_ptr aut = load (file);
  spot::bdd_dict_ptr dict = aut->get_dict ();
  const std::vector<spot::formula> &aps = aut->ap ();
  if (aps.size () > MAX_APS) {
    std::cerr << "spotutil: " << aps.size () << " atomic propositions, too many letters to enumerate" << std::endl;
    return 3;
  }
  std::vector<int> vars;
  for (const spot::formula &ap : aps) vars.push_back (dict->var_map.at (ap));
  unsigned n = aut->num_states ();
  spot::twa_graph_ptr res = spot::make_twa_graph (dict);
  res->copy_ap_of (aut);
  res->set_acceptance (0, spot::acc_cond::acc_code::t ());
  res->new_states (n);
  res->set_init_state (aut->get_init_state_number ());
  size_t letters = size_t (1) << aps.size ();
  for (unsigned q = 0; q < n; ++q) {
    // the automaton read from q
    spot::twa_graph_ptr aq = spot::make_twa_graph (aut, spot::twa::prop_set::all ());
    aq->set_init_state (q);
    bdd accepted = bddfalse;
    for (size_t m = 0; m < letters; ++m) {
      bdd x = bddtrue;
      for (size_t i = 0; i < vars.size (); ++i) x &= ((m >> i) & 1) ? bdd_ithvar (vars[i]) : bdd_nithvar (vars[i]);
      // the word x x x ...: one state, one accepting self-loop, acceptance "t" so the product keeps aq's
      spot::twa_graph_ptr wx = spot::make_twa_graph (dict);
      wx->copy_ap_of (aut);
      wx->set_acceptance (0, spot::acc_cond::acc_code::t ());
      unsigned s0 = wx->new_state ();
      wx->set_init_state (s0);
      wx->new_edge (s0, s0, x);
      if (!spot::product (aq, wx)->is_empty ()) accepted |= x;
    }
    if (accepted != bddfalse) res->new_edge (q, q, accepted);
  }
  spot::print_hoa (std::cout, res, "t");
  std::cout << '\n';
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
  CLI::App *is = app.add_subcommand ("inf-stutter", "Per state, the letters whose infinite repetition is accepted, as an HOA of self-loops.");
  is->add_option ("file", file, "Automaton in HOA format")->required ()->check (CLI::ExistingFile);
  CLI11_PARSE (app, argc, argv);
  if (st->parsed ()) return stutterStates (file);
  if (is->parsed ()) return infStutter (file);
  return sensitivity (file);
}
