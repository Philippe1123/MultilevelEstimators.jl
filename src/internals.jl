## internals.jl : stores estimator internals
#
# A type that stores estimator internals for specific Estimators.
#
# This file is part of MultilevelEstimators.jl - A Julia toolbox for Multilevel Monte
# Carlo Methods (c) Pieterjan Robbe, 2019

abstract type AbstractEstimatorInternals end

# estimator internals
struct EstimatorInternals{T1, T2, T3} <: AbstractEstimatorInternals
	default_internals::T1
	index_set_internals::T2
	sample_method_internals::T3
end

EstimatorInternals(index_set::AbstractIndexSet, sample_method::AbstractSampleMethod, options) =
EstimatorInternals(
				   DefaultInternals(index_set, sample_method, options), 
				   IndexSetInternals(index_set, sample_method, options),
				   SampleMethodInternals(index_set, sample_method, options)
				   )

# default internals are shared by all Estimators
struct DefaultInternals{T1, T2, T3, T4, T5} <: AbstractEstimatorInternals
	samples::T1
	samples_diff::T1
	nb_of_samples::T2
	total_work::T3
	total_time::T3
	current_index_set::T4
	index_set_size::T5
end

function DefaultInternals(index_set, sample_method, options)
	max_search_space = index_set isa Union{AD, U} ? options[:max_search_space] : index_set
	indices = get_index_set(max_search_space, options[:max_index_set_param])

	sz = maximum(indices)
	m = options[:nb_of_qoi] 
	n = sample_method isa MC ? 1 : maximum(options[:nb_of_shifts].(collect(indices))) 

	T = Float64
	samples = [[Vector{T}(undef, 0) for index in CartesianIndices(sz + one(sz))] for i in 1:m, j in 1:n]
	samples_diff = [[Vector{T}(undef, 0) for index in CartesianIndices(sz + one(sz))] for i in 1:m, j in 1:n]

	nb_of_samples = [0 for index in CartesianIndices(sz + one(sz))]
	total_work = [0. for index in CartesianIndices(sz + one(sz))]
	total_time = [0. for index in CartesianIndices(sz + one(sz))]
	current_index_set = Set{Index{ndims(index_set)}}()
	index_set_size = IndexSetSize(0, 0) 

	DefaultInternals(samples, samples_diff, nb_of_samples, total_work, total_time, current_index_set, index_set_size)
end

samples(estimator::Estimator) = estimator.internals.default_internals.samples
samples(estimator::Estimator, n_qoi, n_shift) = estimator.internals.default_internals.samples[n_qoi, n_shift]
samples(estimator::Estimator, n_qoi) = samples(estimator, n_qoi, 1)
samples(estimator::Estimator, n_qoi, n_shift, index::Index) = estimator.internals.default_internals.samples[n_qoi, n_shift][index + one(index)]
samples(estimator::Estimator, n_qoi, index::Index) = samples(estimator, n_qoi, 1, index)

append_samples!(estimator::Estimator, n_qoi, n_shift, index::Index, samples_to_append) = append!(estimator.internals.default_internals.samples[n_qoi, n_shift][index + one(index)], samples_to_append)
append_samples!(estimator::Estimator, n_qoi, index::Index, samples_to_append) = append_samples!(estimator, n_qoi, 1, index, samples_to_append)

samples_diff(estimator::Estimator) = estimator.internals.default_internals.samples_diff
samples_diff(estimator::Estimator, n_qoi, n_shift) = estimator.internals.default_internals.samples_diff[n_qoi, n_shift]
samples_diff(estimator::Estimator, n_qoi) = samples_diff(estimator, n_qoi, 1)
samples_diff(estimator::Estimator, n_qoi, n_shift, index::Index) = estimator.internals.default_internals.samples_diff[n_qoi, n_shift][index + one(index)]
samples_diff(estimator::Estimator, n_qoi, index::Index) = samples_diff(estimator, n_qoi, 1, index)

append_samples_diff!(estimator::Estimator, n_qoi, n_shift, index::Index, samples_to_append) = append!(estimator.internals.default_internals.samples_diff[n_qoi, n_shift][index + one(index)], samples_to_append)
append_samples_diff!(estimator::Estimator, n_qoi, index::Index, samples_to_append) = append_samples_diff!(estimator, n_qoi, 1, index, samples_to_append)

has_samples_at_index(estimator::Estimator, index::Index) = !isempty(estimator.internals.default_internals.samples_diff[1][index + one(index)])

nb_of_samples(estimator::Estimator) = estimator.internals.default_internals.nb_of_samples
nb_of_samples(estimator::Estimator, index::Index) = estimator.internals.default_internals.nb_of_samples[index + one(index)]
add_to_nb_of_samples(estimator::Estimator, index::Index, amount::Integer) = estimator.internals.default_internals.nb_of_samples[index + one(index)] += amount

work(estimator::Estimator, index::Index) = total_work(estimator, index)/nb_of_samples(estimator, index)

total_work(estimator::Estimator) = estimator.internals.default_internals.total_work
total_work(estimator::Estimator, index::Index) = estimator.internals.default_internals.total_work[index + one(index)]

add_to_total_work(estimator::Estimator, index::Index, amount::Real) = estimator.internals.default_internals.total_work[index + one(index)] += amount

time(estimator::Estimator, index::Index) = total_time(estimator, index)/nb_of_samples(estimator, index)

total_time(estimator::Estimator) = estimator.internals.default_internals.total_time
total_time(estimator::Estimator, index::Index) = estimator.internals.default_internals.total_time[index + one(index)]

add_to_total_time(estimator::Estimator, index::Index, amount::Real) = estimator.internals.default_internals.total_time[index + one(index)] += amount

current_index_set(estimator::Estimator) = estimator.internals.default_internals.current_index_set

keys(estimator::Estimator) = sort(collect(current_index_set(estimator)))

push!(estimator::Estimator, index::Index) = push!(estimator.internals.default_internals.current_index_set, index)

clear(estimator::Estimator) = empty!(current_index_set(estimator))

# specific internals related to the sample method
abstract type SampleMethodInternals <: AbstractEstimatorInternals end

struct MCInternals <: SampleMethodInternals end

SampleMethodInternals(index_set, sample_method, options) = MCInternals()

struct QMCInternals{T1} <: SampleMethodInternals
	generators::T1
end

generator(estimator::Estimator{<:AbstractIndexSet, <:QMC}, index) = estimator.internals.sample_method_internals.generators[index + one(index)]
generator(estimator::Estimator{<:AbstractIndexSet, <:QMC}, index, shift) = estimator.internals.sample_method_internals.generators[index + one(index)][shift]

function SampleMethodInternals(index_set, sample_method::QMC, options)
	max_search_space = index_set isa Union{AD, U} ? options[:max_search_space] : index_set
	indices = get_index_set(max_search_space, options[:max_index_set_param])

	sz = maximum(indices)
	R = CartesianIndices(sz + one(sz))
	generators = [[ShiftedLatticeRule(options[:point_generator]) for i in 1:options[:nb_of_shifts](I)] for I in R]

    QMCInternals(generators)
end

# specific internals related to the index set
abstract type IndexSetInternals <: AbstractEstimatorInternals end

struct GenericIndexSetInternals <: SampleMethodInternals end

IndexSetInternals(index_set, sample_method, options) = GenericIndexSetInternals()

struct ADInternals{T1, T2, T3} <: SampleMethodInternals
    old_set::T1
    active_set::T1
    max_index_set::T1
	boundary::T2
    max_search_space::T3
end

function IndexSetInternals(index_set::AD, sample_method, options)
	old_set = Set{Index{ndims(index_set)}}()
	active_set = Set{Index{ndims(index_set)}}()
	push!(active_set, Index(ntuple(i -> 0, ndims(index_set))))
	max_index_set = Set{Index{ndims(index_set)}}()
	boundary = copy(active_set)#Set{Index{ndims(index_set)}}()
	max_search_space = options[:max_search_space]

	ADInternals(old_set, active_set, max_index_set, boundary, max_search_space)
end

active_set(estimator::Estimator{<:AD}) = estimator.internals.index_set_internals.active_set

add_to_active_set(estimator::Estimator{<:AD}, index::Index) = push!(estimator.internals.index_set_internals.active_set, index)

remove_from_active_set(estimator::Estimator{<:AD}, index::Index) = delete!(estimator.internals.index_set_internals.active_set, index)

old_set(estimator::Estimator{<:AD}) = estimator.internals.index_set_internals.old_set

add_to_old_set(estimator::Estimator{<:AD}, index::Index) = push!(estimator.internals.index_set_internals.old_set, index)

is_admissable(estimator::Estimator{<:AD}, index::Index) = is_admissable(estimator.internals.index_set_internals.old_set, index)

max_index_set(estimator::Estimator{<:AD}) = estimator.internals.index_set_internals.max_index_set

add_to_max_index_set(estimator::Estimator{<:AD}, index::Index) = push!(estimator.internals.index_set_internals.max_index_set, index)

boundary(estimator::Estimator{<:AD}) = collect(estimator.internals.index_set_internals.boundary)

update_boundary(estimator::Estimator{<:AD}) = begin
	empty!(estimator.internals.index_set_internals.boundary)
	union!(estimator.internals.index_set_internals.boundary, estimator.internals.index_set_internals.active_set) 
end

clear(estimator::Estimator{<:AD}) = begin
	empty!(current_index_set(estimator))
	empty!(active_set(estimator))
	add_to_active_set(estimator, Index(ntuple(i -> 0, ndims(estimator))))
	empty!(old_set(estimator))
	empty!(max_index_set(estimator))
end

struct UInternals{T1, T2} <: SampleMethodInternals
	accumulator::T1
	max_search_space::T2
end

function IndexSetInternals(index_set::U, sample_method, options)
	max_search_space = options[:max_search_space]
	indices = get_index_set(max_search_space, options[:max_index_set_param])

	m = options[:nb_of_qoi] 
	n = sample_method isa MC ? 1 : maximum(options[:nb_of_shifts].(collect(indices))) 

	accumulator = [Vector{Float64}(undef, 0) for i in 1:m, j in 1:n]

	UInternals(accumulator, max_search_space)
end

# keeps track of max index size parameter sz
mutable struct IndexSetSize{N}
    sz::N
    max_sz::N
end

sz(estimator::Estimator) = estimator.internals.default_internals.index_set_size.sz
max_sz(estimator::Estimator) = estimator.internals.default_internals.index_set_size.max_sz

set_sz(estimator::Estimator, n) = begin
	if estimator isa Estimator{<:AD} && n > max_sz(estimator)
		update_boundary(estimator)
	end
	estimator.internals.default_internals.index_set_size.sz = n
	estimator.internals.default_internals.index_set_size.max_sz = max(sz(estimator), max_sz(estimator))
end