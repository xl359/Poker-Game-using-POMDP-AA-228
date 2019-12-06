#This is a simulator that simulates the game
import Pkg
Pkg.add
Pkg.add("StatsBase")
Pkg.add("Distributions")
Pkg.add("Combinatorics")
Pkg.add("LinearAlgebra")
Pkg.add("QuickPOMDPs")
Pkg.add("POMDPs")
Pkg.add("Distributions")

using POMDPs
POMDPs.add_registry()
Pkg.add("QMDP")
Pkg.add("POMDPSimulators")
Pkg.add("BeliefUpdaters")
Pkg.add("FIB")
Pkg.add("POMDPModels")

#Using imported packages
using StatsBase
using Distributions
using Combinatorics
using LinearAlgebra
using QuickPOMDPs, POMDPSimulators, QMDP
using BeliefUpdaters
using Distributions
using FIB
using POMDPModels
#Includes other files
include("Leduc.jl")

#Creating an instance of Leduc Poker
p = LeducPoker()

#Number of suits
NumSuits=p.NumSuits
#Number of cards in each suit
NumCards=p.NumCards
#Number of rounds
NumRounds=p.NumRounds
#Number of players
NumPlayers=p.NumPlayers

#Creating spaces
function create_space(p::Poker)
    NumSuits = p.NumSuits #Number of Suits
    NumCards = p.NumCards #Number of Cards in each Suit
    NumRounds = p.NumRounds #Number of Rounds
    NumPlayers = p.NumPlayers
    TotalCards = NumSuits*NumCards #Number of Cards
    #Creating Cards, 1,4 smallest; 2,5 medium; 3,6 large cards
    Cards = Vector{Int64}(1:6)
    #Create States, Actions and Observations in tuples
    states = collect(permutations(1:TotalCards,NumPlayers+1)) #Define State Space
    actions = Vector{Int64}(-1:2) #Actions space, -1=fold, 0=check, other=raise
    observationsAction = Vector{Int64}(-1:2)
    observationsCard = Vector{Int64}(0:6)
    observations = Vector{Vector{Int64}}([])
    for i in observationsAction
        for j in observationsCard
            temp = vcat(i,j)
            push!(observations,temp)
        end
    end
    return states, actions, observations
end

#Actually Creating spaces in workspace by calling create_space
space = create_space(p)
states = space[1]
actions = space[2]
observations = space[3]
#Ranom number generator
function T(s::Vector, a::Int64, sp::Vector)
    if s[3] == 0
        if sp[1] == s[1] && sp[2] == s[2] && sp[3] != 0
            return 1/TotalCards
        else
            return 0
        end
    else
        if sp == s
            return 1
        else
            return 0
        end
    end
end

function Z(a::Int64, sp::Vector, o::Vector)
    if a == -1
        if o[1]==-1 && o[2] == sp[3]
            return 1
        else
            return 0
        end
    end
    Distribution1 = normalize([1,10,5,1],1)
    Distribution2 = normalize([1,12,7,1],1)
    Distribution3 = normalize([1,4,7,10],1)
    Distribution = [Distribution1,Distribution2,Distribution3]
    P2First = sp[2]
    #CardStrength evaluates how good or bad a card is
    P2CardStrength = mod(P2First,NumCards)
    if P2CardStrength == 0
        P2CardStrength = 3
    end
    #Probability distribution of Player 2's evaluation of his card
    P2Distribution = Distribution[P2CardStrength]
    #Final probability distribution of Payer 2's actions
    if o[2] == sp[3]
        return P2Distribution[o[1]+2]
    else
        return 0
    end
end

function R(s::Vector,a::Int64)
    P1CardStrength = mod(s[1],3)
    if P1CardStrength == 0
        P1CardStrength = 3
    end
    P2CardStrength = mod(s[2],3)
    if P2CardStrength == 0
        P2CardStrength = 3
    end

    rate=2;
    if mod(s[1],3) == mod(s[3],3)
        return rate*a
    elseif mod(s[2],3) == mod(s[3],3)
        return -rate*a
    elseif P1CardStrength > P2CardStrength
        return rate*a
    elseif P1CardStrength < P2CardStrength
        return -rate*a
    else
        return 0
    end
end
p = LeducPoker()
space = create_space(p)
S = space[1]
A = space[2]
O = space[3]

γ = 0.1

m = DiscreteExplicitPOMDP(S,A,O,T,Z,R,γ)

#solver = FIBSolver()

solver = QMDPSolver()
policy = solve(solver, m)

rsum = 0.0

for (s,b,a,o,r) in stepthrough(m, policy, "s,b,a,o,r", max_steps=3)
    #println("s: $s, b: $([pdf(b,s) for s in S]), a: $a, o: $o")
    global rsum += r
end
println("Undiscounted reward was $rsum.")


function update_belief(p::Poker, b::Vector, a::Int64, o::Vector)
    space = create_space(p)
    states = space[1]
    nb = Array{Float64}([])
    for ns in states
        probserv = Z(a, ns, o)
        sigma = 0 #Sigma over s of T(s'|s,a)*b(s)
        for i = 1:length(states)
            trans = T(states[i], a, ns)
            sigma += trans*b[i]
        end
        temp = probserv*sigma
        push!(nb,temp)
    end
    norm=sum(nb)
    if norm==0
        out=0*nb
    else
        out = nb./norm
    end
    return nb
end

function simulation(stateV::Int64, obsV::Vector)
    statesLeft = Vector{Vector{Int64}}([])
    statesLeftIndex = Vector{Int64}([])
    for i = 1:length(states)
        if states[i][1] == stateV
    #    if states[i][1] == 1
            push!(statesLeftIndex,i)
            push!(statesLeft,states[i])
        end
    end
    NumStatesLeft = length(statesLeft)
    probability1K =zeros(length(states))
    for i = 1:length(states)
        if i in statesLeftIndex
            probability1K[i] = 1/NumStatesLeft
        end
    end
    b = probability1K
    a = action(policy,b)
#    o=[0,1]
    o = obsV
    bp = update_belief(p,b,a,o)
    ap = action(policy,bp)
    return a, ap
end

Va = round.(Int,zeros(6,4))
Vap = round.(Int,zeros(6,4))
for s = 1:6
    for i = -1:2
        aap = simulation(s,[i,5])
        a = aap[1]
        ap = aap[2]
        Va[s,i+2] = a
        Vap[s,i+2] = ap
    end
end
