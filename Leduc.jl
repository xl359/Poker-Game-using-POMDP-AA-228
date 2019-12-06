#This file defines the game, Leduc Hodem

struct Poker
    #Number of suits
    NumSuits
    #Number of cards in each suit
    NumCards
    #Number of rounds
    NumRounds
    #Number of players
    NumPlayers
end

LeducPoker() = Poker(2,3,2,2)
