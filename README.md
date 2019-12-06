# Final-Project
228 Final Project from Xinwei Liu and Zihui Liu
To run this program, first run Lecud.jl. Then if want the action matrix for the blind game, run Finalblind.jl. If want the action matrix for the game where the robot has access to public cards, run Finalopen.jl. The action matrix should be 6 by 4 with the row indicating which card the robot gets, and the column indicating which action the robot takes. Example is listed in the report.
The action for the first policy is called Va. After running the program, type Va in the command should output the matrix. The second policy, which is what we are interested in (the action taken after observing the opponent's action and for the non-blind game, the public card), is accessed by typing Vap
