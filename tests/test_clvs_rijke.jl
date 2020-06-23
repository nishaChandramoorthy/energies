include("../examples/rijke.jl")
include("../src/clvs.jl")
d = 30
u = rand(d)
nRunup = 40000
s = [7.0,0.2]
u = Rijke(u, s, nRunup)
println("Done with Runup")
nSteps = 5000
u_trj = zeros(d,nSteps)
u_trj[:,1] = u
du_trj = zeros(d,d,nSteps)
for i = 2:nSteps
	u_trj[:,i] = Rijke(u_trj[:,i-1], 
				s, 1)
	du_trj[:,:,i] = dRijke(u_trj[:,i],s,1.e-6)
end
println("Done with computing primal and Jacobian 
		trajectory")
println("Getting CLVs...")
# get clvs
les, clv_trj = clvs(du_trj, 10)

