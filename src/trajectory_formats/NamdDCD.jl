#
# Structure to contain DCD trajectories produces with Namd. 
#
"""

$(TYPEDEF)

Structure to contain the data of a trajectory in NAMD/DCD format.

$(TYPEDFIELDS)

"""
struct NamdDCD{T<:AbstractVector} <: Trajectory

    #
    # Mandatory data for things to work
    #
    filename::String
    stream::Stream{<:FortranFile} # special type of stream required for reading DCD files
    nframes::Int64

    # This vector must be filled up with the size of the periodic cell, if it
    # is not defined in the DCD file. 
    sides::Vector{T}

    # Data structures of the solute and solvent 
    solute::Selection
    solvent::Selection

    # Coordinates of the solute and solvent atoms in a frame (3,natoms) for each array:
    x_solute::Vector{T}
    x_solvent::Vector{T}

    #
    # Additional properties that might be required for implementing IO (not necessary for every
    # input/output format)
    #
    sides_in_dcd::Bool # if the DCD contains, or not, periodic cell information for each frame
    lastatom::Int64 # The last atom to be read from each line

    # Auxiliary vectors to read the coordinates without having the allocate/deallocate every time
    sides_read::Vector{Float64}
    x_read::Vector{Float32}
    y_read::Vector{Float32}
    z_read::Vector{Float32}

end

"""
    NamdDCD(filename::String, solute::Selection, solvent::Selection;T::Type = SVector{3,Float64})

This function initializes the structure above, returning the data and the vectors with appropriate lengths.

"""
function NamdDCD(
    filename::String,
    solute::Selection,
    solvent::Selection;
    T::Type = SVector{3,Float64},
)

    st = FortranFile(filename)

    # Read header
    IntVec = Vector{Int32}(undef, 17)
    hdr, read_nframes, IntVec[1:8], ts, IntVec[9:17] =
        read(st, FString{4}, Int32, (Int32, 8), Float64, (Int32, 9))
    dummyi, title = read(st, Int32, FString{80})
    read_natoms = read(st, Int32)

    # Check if dcd file contains axis information
    sides_in_dcd = false
    x = 0.0
    try
        x = read(st, [Float32 for i = 1:read_natoms])
    catch err
        sides_in_dcd = true
    end

    # Get number of frames
    firstframe!(st)
    nframes = getnframes(st, sides_in_dcd)
    lastatom = max(maximum(solute.index), maximum(solvent.index))

    # Most commonly the sides of the box are written in each frame of the DCD file, and will
    # be updated upon reading the frame. Alternatively, the user must provide the sides in all
    # frames by filling up an array with the box side data.
    if sides_in_dcd
        sides = zeros(T, 1)
    else
        sides = zeros(T, nframes)
    end

    # setup the trajectory struct that contains the stream
    stream = Stream(st)

    # Return the stream closed, it is opened and closed within the mddf routine
    FortranFiles.close(st)

    return NamdDCD(
        filename,
        stream,
        nframes,
        sides, # sides vector (if in dcd) or array to be filled up later
        solute,
        solvent,
        zeros(T, solute.natoms), # solute atom coordinates
        zeros(T, solvent.natoms), # solvent atom coordinates
        sides_in_dcd,
        lastatom,
        Vector{Float64}(undef, 6), # auxiliary vector to read sides
        Vector{Float32}(undef, lastatom), # auxiliary x
        Vector{Float32}(undef, lastatom), # auxiliary y
        Vector{Float32}(undef, lastatom),  # auxiliary z
    )

end

function Base.show(io::IO, traj::NamdDCD)
    print(io,""" 
          Trajectory in NamdDCD format containing:
              $(traj.nframes) frames.
              Sides in DCD: $(traj.sides_in_dcd).
          """)
end

#
# Function that opens the trajectory stream
#
opentraj!(trajectory::NamdDCD) = set_stream!(trajectory, FortranFile(trajectory.filename))

#
# Function that closes the IO Stream of the trajectory
#
closetraj!(trajectory::NamdDCD) = FortranFiles.close(stream(trajectory))

#
# Function that reads the coordinates of the solute and solvent atoms from
# the next frame of the trajectory file 
#
# The function modifies sides, x_solute and x_solvent within the trajectory structure.
# Having these vectors inside the trajectory structure avoids having to allocate
# them everytime a new frame is read
#
function nextframe!(trajectory::NamdDCD{T}) where {T}

    st = stream(trajectory)

    # Read the sides of the box from the DCD file, otherwise they must be set manually before
    if trajectory.sides_in_dcd
        read(st, trajectory.sides_read)
        trajectory.sides[1] =
            T(trajectory.sides_read[1], trajectory.sides_read[3], trajectory.sides_read[6])
    end

    # Read the coordinates  
    read(st, trajectory.x_read)
    read(st, trajectory.y_read)
    read(st, trajectory.z_read)

    # Save coordinates of solute and solvent in trajectory arrays
    for i = 1:trajectory.solute.natoms
        trajectory.x_solute[i] = T(
            trajectory.x_read[trajectory.solute.index[i]],
            trajectory.y_read[trajectory.solute.index[i]],
            trajectory.z_read[trajectory.solute.index[i]],
        )
    end
    for i = 1:trajectory.solvent.natoms
        trajectory.x_solvent[i] = T(
            trajectory.x_read[trajectory.solvent.index[i]],
            trajectory.y_read[trajectory.solvent.index[i]],
            trajectory.z_read[trajectory.solvent.index[i]],
        )
    end

    return nothing
end

#
# Function that returns a vector of dimension 3 with the sides of the periodic box 
# given the way that the box side information is stored in the Trajectory structure
#

function getsides(trajectory::NamdDCD, iframe)
    # In this (most common) case, sides is a vector and must only be returned
    if trajectory.sides_in_dcd
        return trajectory.sides[1]
        # otherwise, sides is an array that contains the sides for each frame, and we return the
        # vector containing the sides of the current frame
    else
        return trajectory.sides[iframe]
    end
end

#
# Leave DCD file in position to read the first frame: DCD files have a header
#
function firstframe!(st::FortranFile)
    # rewind
    rewind(st)
    # skip header
    read(st)
    read(st)
    read(st)
end
firstframe!(trajectory::NamdDCD) = firstframe!(stream(trajectory))

#
# Auxiliary functions
#

#
# Sometimes the DCD files contains a wrong number of frames in the header, so to
# get the actual number of frames, it is better to read it
#
function getnframes(st::FortranFile, sides_in_dcd::Bool)
    firstframe!(st)
    nframes = 0
    while true
        try
            if sides_in_dcd
                read(st, Float64)
            end
            read(st, Float32)
            read(st, Float32)
            read(st, Float32)
            nframes = nframes + 1
        catch
            firstframe!(st)
            return nframes
        end
    end
end
getnframes(traj::NamdDCD) = getnframes(stream(traj), traj.sides_in_dcd)
