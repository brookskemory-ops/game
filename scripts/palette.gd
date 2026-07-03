class_name Palette
extends RefCounted
## The single source of color truth (GAME_OVERVIEW.md §6):
## near-black blues & mud browns, lit by torch-orange and cold moonlight.
## Every script pulls colors from here — never hardcode hex elsewhere.

const INK := Color("16131c")        # deepest background
const NIGHT := Color("1b1725")      # night sky low
const NIGHT_HIGH := Color("242033") # night sky high
const IRON := Color("3a3542")       # UI borders, dark metal
const STONE := Color("5a5464")      # tombstones, castle
const ASH := Color("8b8496")        # secondary text
const BONE := Color("cfc9b8")       # skeletons, light stone
const PARCHMENT := Color("d9d3c0")  # primary text
const MOON := Color("cdd5e0")       # moonlight
const TORCH := Color("e08840")      # warm light, XP, highlights
const EMBER := Color("b8542f")      # deep warm accent
const BLOOD := Color("8c2f2f")      # damage, HP
const ROT := Color("6a7a52")        # undead flesh
const POISON := Color("87a659")     # plague green
const GEM := Color("6f9fd8")        # XP gems, cold magic
