#==========================================================================================#

# This file replicates tests from the official documentation of Stata
# Some DOF adjustements are necessary because Stata uses different corrections

#==========================================================================================#

# MISE EN PLACE

using Base.Test
using CSV
using DataFrames
using Microeconometrics
using StatsModels

const datadir = joinpath(dirname(@__FILE__), "..", "data")

#==========================================================================================#

S        = CSV.read(joinpath(datadir, "auto.csv"))
S[:gpmw] = ((1.0 ./ S[:mpg]) ./ S[:weight]) * 100000
M        = Dict(:response => "gpmw", :control => "foreign + 1")

@testset "OLS_Homoscedastic" begin

    D = Microdata(S, M, vcov = Homoscedastic())
    E = fit(OLS, D)

    β = [0.24615258; 1.60900394]
    s = [0.05494872; 0.02996078]

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test isapprox(r2(E), 0.21796522, atol = 1e-7)
    @test isapprox(adjr2(E), 0.20710363, atol = 1e-7)
    @test dof(E) == 2
end

@testset "OLS_Heteroscedastic" begin

    D = Microdata(S, M, vcov = Heteroscedastic())
    E = fit(OLS, D)

    β = [0.24615258; 1.60900394]
    s = [0.06792384; 0.02345347]
    c = (nobs(E) - dof(E)) / (nobs(E) - 1)
    s = s * sqrt(c)

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test isapprox(r2(E), 0.21796522, atol = 1e-7)
    @test isapprox(adjr2(E), 0.20710363, atol = 1e-7)
    @test dof(E) == 2
end

T        = Dict("age" => Union{Int, Missing})
S        = CSV.read(joinpath(datadir, "regsmpl.csv"), types = T)
S[:age2] = Array{eltype(S[:age])}(S[:age].^2)
W        = Clustered(S, :idcode)
M        = Dict(:response => "ln_wage", :control => "age + age2 + tenure + 1")

@testset "OLS_Clustered" begin

    D = Microdata(S, M, vcov = W)
    E = fit(OLS, D)

    β = [0.07521723; -0.00108513; 0.03908767; 0.33398213]
    s = [0.00457113;  0.00007785; 0.00144254; 0.06419184]
    c = (nobs(E) - dof(E)) / (nobs(E) - 1)
    s = s * sqrt(c)

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test isapprox(r2(E), 0.16438516, atol = 1e-7)
    @test isapprox(adjr2(E), 0.16429594, atol = 1e-7)
    @test dof(E) == 4
end

#==========================================================================================#

S = CSV.read(joinpath(datadir, "hsng2.csv"))
M = Dict(
        :response   => "rent",
        :control    => "pcturban + 1",
        :treatment  => "hsngval",
        :instrument => "faminc + region"
    )

@testset "TSLS" begin

    D = Microdata(S, M, vcov = Homoscedastic())
    E = fit(IV, D)

    β = [0.00223983; 0.08151597; 120.70651454]
    s = [0.00033876; 0.30815277;  15.70688390]

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test isapprox(r2(E), 0.59888202, atol = 1e-7)
    @test isapprox(adjr2(E), 0.58181317, atol = 1e-7)
    @test dof(E) == 3
end

#==========================================================================================#

S = CSV.read(joinpath(datadir, "lbw.csv"))
M = Dict(:response => "low", :control => "age + lwt + race + smoke + ptl + ht + ui + 1")
C = Dict(:race => DummyCoding(base = "white"))
D = Microdata(S, M, vcov = Homoscedastic(), contrasts = C)

@testset "Logit" begin

    E = fit(Logit, D)

    β = [-0.02710031; -0.01515082; 1.26264728; 0.86207916; 0.92334482;
          0.54183656;  1.83251780; 0.75851348; 0.46122388]
    s = [ 0.03645043;  0.00692588; 0.52641014; 0.43915315; 0.40082664;
          0.34624900; 0.69162923; 0.45937677; 1.20458975]

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test isapprox(deviance(E), 201.44799113, atol = 1e-7)
    @test isapprox(loglikelihood(E), -100.72399557, atol = 1e-7)
    @test isapprox(nullloglikelihood(E), -117.33599810, atol = 1e-7)
    @test isapprox(aic(E), 219.44799113, atol = 1e-7)
    @test isapprox(aicc(E), 220.45357772, atol = 1e-7)
    @test isapprox(bic(E), 248.62371427, atol = 1e-7)
    @test dof(E) == 9
end

@testset "Probit" begin

    E = fit(Probit, D)

    β = [-0.01754447; -0.00882045; 0.74752563; 0.51447107; 0.56276006;
          0.31782665;  1.09945075; 0.46279438; 0.26827531]
    s = [ 0.02162924;  0.00397343; 0.31664054; 0.25558235; 0.23577825;
          0.20012526;  0.41927933; 0.27560931; 0.70152540]

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test isapprox(deviance(E), 201.12189887, atol = 1e-7)
    @test isapprox(loglikelihood(E), -100.56094943, atol = 1e-7)
    @test isapprox(nullloglikelihood(E), -117.33599810, atol = 1e-7)
    @test isapprox(aic(E), 219.12189887, atol = 1e-7)
    @test isapprox(aicc(E), 220.12748546, atol = 1e-7)
    @test isapprox(bic(E), 248.29762201, atol = 1e-7)
    @test dof(E) == 9
end

@testset "Cloglog" begin

    E = fit(Cloglog, D)

    β = [-0.02309612; -0.01129839; 1.07937099; 0.72856146; 0.73324598;
          0.33131635;  1.42557598; 0.56457925; -0.09224780]
    s = [0.02906676; 0.00521572; 0.40185917; 0.32942310; 0.30247340;
         0.20833347; 0.45334563; 0.34357409; 0.90994949]

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test isapprox(deviance(E), 202.16661013, atol = 1e-7)
    @test isapprox(loglikelihood(E), -101.08330506, atol = 1e-7)
    @test isapprox(nullloglikelihood(E), -117.33599810, atol = 1e-7)
    @test isapprox(aic(E), 220.16661013, atol = 1e-7)
    @test isapprox(aicc(E), 221.17219672, atol = 1e-7)
    @test isapprox(bic(E), 249.34233326, atol = 1e-7)
    @test dof(E) == 9
end

#==========================================================================================#

S          = CSV.read(joinpath(datadir, "dollhill3.csv"))
S[:pyears] = log.(S[:pyears])

M  = Dict(
        :response => "deaths",
        :control => "smokes + agecat + 1",
        :offset => "pyears"
    )

@testset "Poisson" begin

    D = Microdata(S, M, vcov = Homoscedastic())
    E = fit(Poisson, D)

    β = [0.35453564; 1.48400701; 2.62750512; 3.35049279; 3.70009645; -7.91932571]
    s = [0.10737412; 0.19510337; 0.18372727; 0.18479918; 0.19221951;  0.19176182]

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test isapprox(deviance(E), 12.13236640, atol = 1e-7)
    @test isapprox(loglikelihood(E), -33.60015344, atol = 1e-7)
    @test isapprox(nullloglikelihood(E), -495.06763568, atol = 1e-7)
    @test isapprox(aic(E), 79.20030688, atol = 1e-7)
    @test isapprox(aicc(E), 107.20030688, atol = 1e-7)
    @test isapprox(bic(E), 81.01581744, atol = 1e-7)
    @test dof(E) == 6
end

#==========================================================================================#

S         = CSV.read(joinpath(datadir, "cattaneo2.csv"))
S[:mage2] = S[:mage].^2

M = Dict(
        :response  => "bweight",
        :control   => "mmarried + mage + mage2 + fbaby + medu + 1",
        :treatment => "mbsmoke",
    )

@testset "IPW" begin

    D = Microdata(S, M)
    E = fit(IPW, Probit, D)

    β = [-230.68863780; 3403.46270868]
    s = [  25.81524380;    9.57136890]
    c = nobs(E) / (nobs(E) - 1)
    s = s * sqrt(c)

    @test isapprox(coef(E), β, atol = 1e-7)
    @test isapprox(stderr(E), s, atol = 1e-7)
    @test dof(E) == 2
end
