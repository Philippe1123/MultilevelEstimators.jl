## estimators.jl : main Estimator type
#
# Representation of the main Estimator type.
#
# This file is part of MultilevelEstimators.jl - A Julia toolbox for Multilevel Monte
# Carlo Methods (c) Pieterjan Robbe, 2018

## Estimator ##
struct Estimator{I<:AbstractIndexSet, S<:AbstractSampleMethod, D, O, N}
    index_set::I
    sample_function::Function
    distributions::D
    options::O
    internals::N
end

function Estimator(index_set::AbstractIndexSet, sample_method::AbstractSampleMethod, sample_function::Function, distributions::Vector{<:AbstractDistribution}; kwargs...)

    # read optional arguments
    settings = Dict{Symbol,Any}(kwargs)
    check_valid_keys(settings, index_set, sample_method)
    
    # default settings
    settings[:distributions] = distributions
    for key in valid_keys(index_set, sample_method)
        parse!(index_set, sample_method, settings, key)
    end

    # create options, base_estimator...
    options = EstimatorOptions(settings)
    internals = EstimatorInternals(index_set, sample_method, settings)
    
    Estimator{typeof(index_set), typeof(sample_method), typeof(distributions), typeof(options), typeof(internals)}(index_set, sample_function, distributions, options, internals)
end

Estimator(index_set::AbstractIndexSet, sample_method::AbstractSampleMethod, sample_function::Function, distribution::AbstractDistribution; kwargs...) = Estimator(index_set, sample_method, sample_function, [distribution]; kwargs...)

## check valid keys ##
function check_valid_keys(settings::Dict, index_set::AbstractIndexSet, sample_method::AbstractSampleMethod)
    for key in keys(settings)
        key ∉ valid_keys(index_set, sample_method) && throw(ArgumentError(string("in Estimator, invalid key ", key, " found")))
    end
end

## valid keys ##
valid_keys(index_set::AbstractIndexSet, sample_method::AbstractSampleMethod) = vcat(valid_keys(), valid_keys(index_set), valid_keys(sample_method))

valid_keys() = collect(fieldnames(EstimatorOptions))

valid_keys(::AbstractSampleMethod) = Symbol[]
valid_keys(::QMC) = [:nb_of_shifts, :point_generator, :sample_mul_factor]
valid_keys(::MC) = [:do_regression]

valid_keys(::AbstractIndexSet) = Symbol[]
valid_keys(::AbstractAD) = [:max_search_space]
valid_keys(::MG) = [:sample_mul_factor]
valid_keys(::MG{<:AD}) = [:sample_mul_factor, :max_search_space]

## print methods ##
show(io::IO, estimator::Estimator{I,S}) where {I<:AbstractIndexSet, S<:AbstractSampleMethod} = print(io, string("Estimator{", estimator.index_set, ", ", S, "}"))