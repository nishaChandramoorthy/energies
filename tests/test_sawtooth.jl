include("sawtooth.jl")
include("clvs.jl")
include("lss.jl")
using Test
function test_dsawtooth()
	s = rand()
	m = 10
	u_trj = rand(m)
	eps = 1.e-4
	du_fd = (sawtooth(u_trj .+ eps,
						s, 1)[2,:] - 
				sawtooth(u_trj .- eps, 
						s, 1)[2,:])./(2*eps)
	du = dsawtooth(u_trj, s)
	@assert all(isapprox.(du_fd, du)) == 1
end
function test_les()
	s = 0.01
	m = 1
	n = 25000
	u0 = rand(m)
	u_trj = sawtooth(u0, s, n)[:,1]
	n = n+1
	du_trj = reshape(dsawtooth(u_trj, s),1,1,n)
	les, clv_trj = clvs(du_trj,1)
	println(les)
	@assert all(isapprox.(les, log(2), 
						  rtol=1.e-1)) == 1
end
function test_lss()
	s = 0.01
    m = 1
    n = 5000
    u0 = rand(m)
	d = 1
    d_u = 1
	dJ = ones(d,n+1)
	n_samples = 10
	dJds = zeros(n_samples)
	vsh = zeros(d,n+1)
	
	for i=1:n_samples
		println("Starting LSS, sample ", i)
		u_trj = sawtooth(u0, s, n)[:,1]
		du_trj = reshape(dsawtooth(u_trj, s),d,d,n+1)
		X = reshape(perturbation(u_trj,s),d,n+1) 
		f = zeros(1,n+1)	
		J = u_trj
		u_trj = reshape(u_trj, n+1, d)
		y, dJds[i] = lss(u_trj,  
						du_trj, X, f, J, dJ, 
						  s, d_u)
		println(dJds[i])
		vsh .= y
		u0 .= u_trj[end,:]
	end
	println("Sensitivities are : ", dJds)
	@test isapprox((sum(dJds)/n_samples),-0.61,rtol=0.1)  
	return vsh, dJds
end
