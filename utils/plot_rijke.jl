include("../examples/rijke.jl")
using PyPlot
using JLD
function plot_sensitivity()
	vsh, dJds = test_lss()
	fig, ax = subplots(1,1)
	fig1, ax1 = subplots(1,1)
	vsh = vsh[:,100:end,10]'
	n = 0.005*(axes(vsh)[1] .- 1.)
	n_samples = size(dJds)[1]
	dJds_avg = sum(dJds)/n_samples
	var_dJds = sum(x -> x^2, dJds .- dJds_avg)/n_samples
	ax.plot(n, vsh[:,1], label=L"v_{\rm sh,x}")
	ax.plot(n, vsh[:,2], label=L"v_{\rm sh,y}")
	ax.plot(n, vsh[:,3], label=L"v_{\rm sh,z}")
	ax.set_xlabel("time",fontsize=18)
	ax.set_ylabel("components of the shadowing direction",
					  fontsize=18)
	ax.xaxis.set_tick_params(labelsize=18)
	ax.yaxis.set_tick_params(labelsize=18)
	fig.legend(fontsize=18)
	ax1.set_ylabel("sensitivities from NILSS",fontsize=18)
	ax1.set_xlabel("sample number",fontsize=18)
	ax1.set_title("trajectory length = 5000", fontsize=18)
	ax1.xaxis.set_tick_params(labelsize=18)
	ax1.yaxis.set_tick_params(labelsize=18)
	ax1.grid(true)
	ax1.errorbar(x=1:n_samples,y=dJds,yerr=sqrt(var_dJds),
			 linestyle="none",ms=4)
	ax1.plot(sum(dJds)/n_samples*ones(n_samples),"--")
	#mean value: 0.905328466, variance = 0.042, without 
	# time dilation
end
function plot_condition_number()
	dJds, condnum = test_condition_number()
	fig, ax = subplots(1,1)
	n_samples = size(dJds)[1]
	n_arr = StepRange(500, 155, 5000)
	ax.plot(n_arr, condnum, ".", ms=10.0)
	ax.set_xlabel("trajectory length",fontsize=18)
	ax.set_ylabel("condition number",
					  fontsize=18)
	ax.xaxis.set_tick_params(labelsize=18)
	ax.yaxis.set_tick_params(labelsize=18)
end
function plot_da_err(z_prd,z_obs,fig, ax)
	n_trj, n_gd, n_exps = size(z_prd)
	z_opt_prd = view(z_prd, :, n_gd, :)
	err = abs.((z_obs .- z_opt_prd)./z_obs)
	max_err = findmax(err, dims=1)[1][:]
	max_err = log.(max_err)
	max_err = max_err .- minimum(max_err)
	norm_max_err = max_err/maximum(max_err)
	clr_map = plt.get_cmap("winter")
	clr_acc_err = clr_map(norm_max_err)
	times = dt*LinRange(0,n_trj,n_trj)
	times = times
	err = err
	for i = 1:n_exps
		ax.semilogy(times, err[:,i], ".", 
					ms=0.5,color=clr_acc_err[i,:])
	end
	mean_err = (sum(err, dims=2)/n_exps)[:]
	std_err = sum((err .- mean_err).^2.0, dims=2)/n_exps
	std_err = sqrt.(std_err[:])
	ax.semilogy(times, mean_err, ".", color="k",ms=2.0)
end
function read_error_files()
	n_times_1 = 4
	n_exps_t = 15
	n_times_2 = 8
	n_exps = (n_times_1 + n_times_2)*n_exps_t
	filenames = Array{String,1}(undef, n_exps) 
	for i = 1:n_times_1
		for j = 1:n_exps_t
			filenames[(i-1)*n_exps_t + j] = string(
			"../data/rijke_DA/1-to-60/rijke_exp", 
			string(i+1), "_", string(j), ".jld")
		end
	end
	n_cltd = n_times_1*n_exps_t
	for i = 1:n_times_2
		for j = 1:n_exps_t
			filenames[n_cltd + (i-1)*n_exps_t + j] = string(
			"../data/rijke_DA/61-to-180/rijke_exp", 
			string(i+1), "_", string(j), ".jld")
		end
	end

	data = load(filenames[1])
	prd = data["z_prd"]
	obs = data["z_obs"]
	n_trj, n_gd, x = size(prd)
	z_prd = zeros(n_trj, n_gd, n_exps)
	z_obs = zeros(n_trj, n_exps)
	z_prd[:,:,1] = prd[:,:,1]
	z_obs[:,1] = obs[:,1]
	for k = 2:n_exps 
		data = load(filenames[k])
		prd = data["z_prd"]
		obs = data["z_obs"]
		z_prd[:,:,k] = prd[:,:,1]
		z_obs[:,k] = obs[:,1]
	end
	
	fig, ax = subplots(1,1)

	ax.xaxis.set_tick_params(labelsize=24)
	ax.yaxis.set_tick_params(labelsize=24)
	ax.set_xlabel("time", fontsize=24)
	ax.set_ylabel("Prediction error", fontsize=24)
	ax.grid(true)

	plot_da_err(z_prd,z_obs,fig, ax)

end
