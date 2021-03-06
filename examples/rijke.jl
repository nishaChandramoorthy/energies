# Rijke tube model
# Reference: Huhn and Magri 2020
using LinearAlgebra
#using DiffEqSensitivity, OrdinaryDiffEq, Zygote
include("cheb.jl")
# s = [beta, tau]
c1 = 0.1
c2 = 0.06
xf = 0.2
Ng = 10
tNg = 2*Ng + 1
Nc = 10
N = 2*Ng + Nc
j = LinRange(1,Ng,Ng)
jpi = @. pi.*j
cjpixf = @. cos.(xf.*jpi)
sjpixf = @. sin.(xf.*jpi)
zetaj = @. c1.*j.*j .+ c2.*
		sqrt.(j)
coeffs = [-1.0, 0.0, 1.75e3, 6.2e-12, -7.5e6]
tau = 0.2
dt = 5.e-1/Nc*tau
function qfun(t)
	if abs(t + 1.0) > 0.005 
		return sqrt(abs(1.0 + t)) - 1.0
	end
	q = 0.
	for i = 1:5
		q += coeffs[i]*((1+t)^(i-1))
	end
	return q 
end	

D = cheb_diff_matrix(Nc)
function Rijke(u0::Array{Float64,1}, 
			   s::Array{Float64,1}=[7.0, 0.2],
			   n::Int64=1)
	uDot1 = zeros(N)
	uDot2 = zeros(N)
	uDot3 = zeros(N)
	beta, tau = s
	#ufMean = zeros(n)
	u = copy(u0)
	for i = 1:n
		#ufMean[i] = dot(u0[1:Ng],cjpixf)
		un = copy(u)
		f!(uDot1, u, s, i)
		@. u = u + (1/2)*dt*uDot1
		f!(uDot2, u, s, i)
		@. u = u - dt*uDot1 + 
			2*dt*uDot2
		f!(uDot3, u, s, i)
		@. u = un + dt*((1/6).*uDot1 + 
					 (2/3)*uDot2 + (1/6)*uDot3)
	end
	return u
end
function Rijke_ODE(u0::Array{Float64,1}, 
			   s::Array{Float64,1}=[7.0, 0.2],
			   n::Int64=1)
	t = n*dt
	prob = ODEProblem(f!, u0, (0.,t), s)
	sol = Array(solve(prob, Tsit5(),saveat=dt))
	return sol[:,end]
end
function f!(uDot, u, s, t)
	eta = view(u, 1:Ng)
	mu = view(u, Ng+1:2*Ng)
	v = view(u, tNg:N)
	beta, tau = s
	heat = beta*qfun(v[1])
	@. uDot[1:Ng] = jpi*mu
	@. uDot[Ng+1:2*Ng] = -jpi*eta - zetaj*mu - 2.0*heat*
						sjpixf
	uDot[tNg:N] .= -2.0/tau.*(D*[v; 
					dot(eta, cjpixf)])[1:end-1]
end
function dfdbeta(u,s)
	n, d = size(u)
	beta, tau = s
	v1 = u[:,2*Ng + 1] 
	dheat = qfun.(v1)
	return reshape([zeros(Ng*n); 
					kron(-2.0.*ones(n).*dheat, sjpixf);
					zeros(Nc*n)], d, n)
end
function perturbation(u, s, eps=1.e-6)
	d, = size(u)
	beta, tau = s
	return (Rijke(u, [beta + eps, tau], 1) - 
			Rijke(u, [beta - eps, tau], 1))/(2*eps)
end
function tau_perturbation(u, s, eps=1.e-6)
	d, = size(u)
	beta, tau = s
	return (Rijke(u, [beta, tau + eps], 1) - 
			Rijke(u, [beta, tau - eps], 1))/(2*eps)
end

function dRijke(u, s, eps)
	d,  = size(u)
	dTu = zeros(d,d)
	u_p = zeros(d)
	u_m = zeros(d)
	v0 = zeros(d)
	for j = 1:d
		v0 .= zeros(d)
		v0[j] = 1.0
		u_p .= u .+ eps*v0
		u_m .= u .- eps*v0

		dTu[:,j] = (Rijke_ODE(u_p, s, 1) - 
					Rijke_ODE(u_m, s, 1))/(2*eps)
	end
	return dTu
end
function dRijke_AD(u, s, eps=0.)
    du_ad = zeros(d,d)
    for j = 1:d
        v = zeros(d)
        du_ad[:,j] = Zygote.gradient(v->
                Rijke_ODE(u .+ v, s, 1)[j],v)[1]
    end
    return du_ad'
end    

