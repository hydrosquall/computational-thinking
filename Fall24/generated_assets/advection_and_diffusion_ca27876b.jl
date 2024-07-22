### A Pluto.jl notebook ###
# v0.19.45

#> [frontmatter]
#> chapter = 3
#> video = "https://www.youtube.com/watch?v=Xb-iUwXI78A"
#> image = "https://user-images.githubusercontent.com/6933510/136200627-8211654f-7730-4f4a-8933-5b64164806c3.gif"
#> section = 7
#> order = 7
#> title = "Advection and diffusion in 1D"
#> layout = "layout.jlhtml"
#> youtube_id = "Xb-iUwXI78A"
#> description = ""
#> tags = ["lecture", "module3", "advection–diffusion", "climate", "modelling", "PDE", "differential equation", "track_math", "track_climate", "simulation", "plotting", "fluid simulation", "continuous"]

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ e0c0dc94-277e-11eb-379e-83d064a93413
using Plots, PlutoUI, LinearAlgebra

# ╔═╡ 5648fa26-da0b-41d9-b13f-debd4e0485af
TableOfContents(depth=4)

# ╔═╡ 00877a4a-277c-11eb-3ec0-e71e4094b404
md"""
# Evolution in time and space: Advection and diffusion in 1D
"""

# ╔═╡ 1b25b916-277c-11eb-0274-4b4fb946258d
md"""
So far we have been looking at dynamics in time, for example how does the temperature of the Earth change over time. But the Earth does not have a single, uniform temperature; rather, at a particular moment in time, different places on Earth are at different temperatures, and those different temperatures change over time due to several mechanisms. 

In this notebook we will look at two fundamental mechanisms: **advection** and **diffusion**. Let's think about the temperature in the ocean. Since the ocean is a fluid that is in motion, a warm "parcel" of water can flow (move) to a new location due to the physical motion of the water itself; this is **advection**.  And even if the water doesn't move, temperature or a higher concentration of some substance dissolved in the fluid can spread out due to molecular mechanisms; this is **diffusion**.
"""

# ╔═╡ 956f5104-277d-11eb-291d-1faef485a5aa
md"""
In this notebook we will restrict ourselves to one spatial dimension (1D).
So we will think about the temperature $T$, for example, being a function 

$$T(t, x)$$

of two independent variables:

- time, $t$
- space, $x$


We want to calculate a value of the temperature $T$ for each possible pair of values $(t, x)$, i.e. for all time ($>0$) and all positions.

The temperature at a given point will change due to different physical processes. We need to model this by writing down equations describing each physical process and how it affects the temperature. Since there are now *two* independent variables, $t$ and $x$, we can expect to end up with derivatives with respect to *both* of these variables, so that the rate of change of temperature in time at a given point depends also on gradients of the temperature in *space*. This will lead to a **partial differential equation** that relates *partial* derivatives of $T$.

In the context of climate modelling, we can think of $x$ as being the **latitude**, supposing that the temperature is the same at all points with the same latitude. In this way we could model the fact that the poles are cold and the equator is warm, and we could model how heat flows from hot to cold. 

However, we clearly cannot model actual ocean currents like this, which would require two, or even three, spatial dimensions.

"""

# ╔═╡ b12e76db-1a18-465a-8955-dab29dfde611
md"""
## Visualising advection--diffusion
"""

# ╔═╡ c14470f2-d8a4-4d34-8470-09842b2576a3
md"""
Here is a visualisation of the physical processes of advection and diffusion in one dimension that we will discuss and build during this notebook.
"""

# ╔═╡ b04a6f81-3ece-4521-b141-a2e416718948
md"""
U = $(@bind UU Slider(-1:0.01:1, show_value=true, default=0))

D = $(@bind DD Slider(-0.2:0.001:0.2, show_value=true, default=0))
"""

# ╔═╡ 36328b70-277d-11eb-02c7-2f854c1466cc
md"""
# Temperature profiles and discretization
"""

# ╔═╡ 42190984-277d-11eb-1ac2-7d84516c3269
md"""
An ordinary differential equation needs an initial value for each variable. Similarly, we will need an initial *function* $T_0(x)$ that gives us the temperature at each position $x$. Let's suppose that the position is restricted to the interval $[0, L_x]$.

As usual, to represent the continuous function $T_0(x)$ on a computer, we will need to **discretise** it in some way, i.e. *approximate* the continuous function by a *finite* set of numbers in the computer.

The simplest (but far from the only!) discretisation method is to **sample** the function at discrete **grid points** (or **nodes**) $x_i$, for $i = 1, \dots, N_x$. For simplicity we will take these equally spaced, with spacing $x_{i+1} - x_i =: \delta x := L_x / N_x$.
"""

# ╔═╡ d2bed768-277e-11eb-32cf-41f1fedec3cb
md"""
For example, let's consider the following initial temperature profile:
"""

# ╔═╡ e6493da0-277e-11eb-22ff-29752652b576
# T₀(x) = sin(2π * x)^2 + 0.5

T₀(x) = sin(2π * x) + 2*cos(4π * x) + 0.2

# ╔═╡ 0d6271c0-286c-11eb-1c9c-3ba039b49d24
md"""
and define the grid points as follows:
"""

# ╔═╡ f17f7734-277e-11eb-25cf-5f2ba2db5aa3
begin
	Nₓ = 20
	Lₓ = 1.0
	
	δx = Lₓ / Nₓ
	
	xs = δx/2:δx:Lₓ
end

# ╔═╡ fa327c08-286b-11eb-0032-2384998a42a8
xs

# ╔═╡ 0db43be2-284c-11eb-2740-4379437fd70c
md"""
It turns out to be a good idea to take the grid points at the *centre* of each interval, so that we have $N_x$ intervals and $N_x$ grid points, starting at $x_1 = \delta x/2$ and finishing at $x_N = L_x - \delta x / 2$.
"""

# ╔═╡ 468a0590-2780-11eb-045c-d1f468fc4e50
md"""
We call such a function of $x$ at a given time a **temperature profile**. Let's draw it both as a function and as a heatmap:
"""

# ╔═╡ af30a0d0-2781-11eb-0274-ab423205facb
md"""
We will denote by $T^0_i$ the initial temperature at grid point number $i$.
"""

# ╔═╡ 646bc32e-284c-11eb-2ce8-5f64b1a49534
md"""
A useful way to think about $T^n_i$ is as some kind of (spatial) average of $T(t_n, x)$ over the interval of positions between neighbouring grid points, so $T_i$ is the average over the interval between $x_i - \frac{\delta x}{2}$ and $x_i + \frac{\delta x}{2}$. We can thus think of the following **piecewise constant** approximation to the original continuous function:
"""

# ╔═╡ 79ce4b10-284c-11eb-2258-2155f850171d
let
	δx = xs[2] - xs[1]
	
	p = plot(0:0.001:Lₓ, T₀, label="T₀", lw=1, ls=:dash)
	scatter!(xs, T₀.(xs), label="sampled")
	scatter!(xs, zero.(xs), label="x nodes", alpha=0.5, ms=3, lw=2)
	
	for i in 1:length(xs)
		plot!([ (xs[i] - δx/2, T₀(xs[i])), (xs[i] + δx/2, T₀(xs[i])) ], c=:green, lw=4, lab=false)
		
		plot!([ (xs[i] - δx/2, 0), (xs[i] - δx/2, T₀(xs[i])), (xs[i] + δx/2, T₀(xs[i])), (xs[i] + δx/2, 0)], c=:green, lw=1, lab=false, ls=:dash, alpha=0.3
		)
	end
	
	xlabel!("x")
	ylabel!("T₀(x)")
end

# ╔═╡ 2494daaa-2780-11eb-3084-2317924048ea
md"""
# Advection
"""

# ╔═╡ 29444ffe-2780-11eb-0875-095302b5d486
md"""
Now let's think of this profile as representing the temperature in each small volume, or "parcel", of fluid. Let's suppose that the fluid is moving to the right with a constant, uniform speed $U$. (**Uniform** here means that the speed is the same in all parts of the fluid.) Then the temperature profile should also *move with the fluid*! We call a quantity, such as the temperature, that is carried along with the fluid a **tracer**.

If we fix our attention at a single, fixed point in space, say the grid point $x_i$, the temperature there will vary over time, due to the fact that the fluid is moving past it. How it varies in time depends on the values at neighbouring grid points, since they determine how much heat will be transported *into* and *out of* the current cell.

[The point of view where we fix our attention at one point in space is called **Eulerian**. The alternative is to follow a parcel of fluid as it moves along in space; this is called **Lagrangian**.]
"""

# ╔═╡ 1dcb9690-6436-49f0-880f-23490fe28ea4
md"""
## Visualising fluxes in a fluid
"""

# ╔═╡ b63bb2e8-1d23-48fb-94b5-60d947465830
md"""
Let's visualise what happens as the fluid moves past a grid point, or rather the cell centered at a grid point. We will visualise tracer particles moving inside the fluid:
"""

# ╔═╡ e94a90c5-f2c1-4b5b-9946-7869ef7775a6
N = 5000

# ╔═╡ dd87fc01-4bf0-44f6-a9f6-560e433754a0
begin
	xx = ( abs.(-2 .+ 4 .* rand(N)) .^ 2) .- 1.5
	yy = rand(N)
end

# ╔═╡ 7ae9f5b8-10ea-42a7-aa01-0e04a7287c77
δ = 0.8

# ╔═╡ 2f24e0c7-b05c-4f89-835a-081f8e6107e5
md"""
show particles entering and leaving in $\delta t$: $(@bind show_particles CheckBox())
"""

# ╔═╡ 75bc87be-2b66-46b5-8de8-428a63655815
md"""
t = $(@bind t Slider(0:0.001:2, show_value=true, default=0))
"""

# ╔═╡ 3437e53b-9dd0-4afe-a1bd-a556871d1799
md"""
## Time stepping
"""

# ╔═╡ 65df7158-60dc-4809-82a3-913a79bcfc75
md"""
We want to model how the temperature profile changes in time due to the flow of the fluid. We'll do so by looking at each cell and asking how much heat enters and leaves the cell in a given time step, of duration $\delta t$.
"""

# ╔═╡ 7256778a-2785-11eb-0369-f3b43d5dd203
md"""
Let's call $T^n_i$ the approximate (unknown) average value of $T$ in the cell at position $x_i$ and at the $n$th time step $t_n$, i.e. an approximation of $T(t_n, x_i)$, where $t_n = n \, \delta t$. 

Then $T^{n+1}_i \simeq T(t_n + \delta t, x_i)$ and $T^{n}_{i+1} \simeq T(t_n, x_i + \delta x)$.

[Note that the superscript $n$ in these algorithms does not mean a power; it's just a label for the time step. We could write $T_i^{(n)}$ instead, but that is annoying to both write and read, so we omit the parentheses.]


"""

# ╔═╡ 44433a34-2782-11eb-0079-837c9306c5bd
md"""
Suppose the fluid is moving to the right with speed $U$. During a time step of duration $\delta t$, the temperature $T^n_i$ at cell $i$ changes for two reasons:

- some heat enters cell $i$
- some heat leaves cell $i$ 

Note that most of the fluid that starts within cell $i$ remains within that cell during the time step (if the time step is short enough), as we see from the visualisation above. 

To calculate how much heat enters and leaves, note that only heat in the region of fluid within a distance $U \, \delta t$ from the boundary of the cell will cross into that cell. So a *proportion* $(U \, \delta t) / \delta x$ of the amount in cell $i$ crosses the boundary.

[We will blur the distinction between "amount of heat" and temperature.]

Hence, roughly an amount $T^n_i (U \delta t) / \delta x$ will leave cell number $i$ and cross into cell $i+1$ (the cell to the right). Similarly, an amount $T^n_{i-1} (U \delta t) / \delta x$ will *enter* cell $i$ from the neighbouring cell $i-1$ on the left. 

Hence we arrive at the following:

$$T^{n+1}_i = T^{n}_i + (T^n_{i-1} - T^n_{i})\, U \, \delta t / \delta x.$$

Note that on the right-hand side we have quantities at the time step $n$, and on the left at time step $n+1$. So this tells us how to *update* our quantities from slice $n$ to slice $n+1$.

"""

# ╔═╡ 87e2be25-227c-498c-94fa-6e404c8918f1
md"""
## Continuous limit: Advection equation PDE
"""

# ╔═╡ 72c0ab0c-2781-11eb-1f59-9b22a52b0be0
md"""
Rearranging the previous equation we get 

$$\frac{T^{n+1}_i - T^{n}_i}{\delta t} =  \frac{T^n_{i-1} - T^n_{i}}{\delta x}\,  U.$$
"""

# ╔═╡ e5761990-278b-11eb-134e-7954b577b1ac
md"""
Taking the continuum limit when $\delta t \to 0$ and $\delta x \to 0$, we recognise the definition of **partial derivatives** with respect to time and space variables from multivariable calculus. (Note the different indices that change on the two sides of the equation.) 

Denoting these partial derivatives using $\partial$, we arrive at the **advection equation**:

$$\frac{\partial T(t, x)}{\partial t} = -U \frac{\partial T(t, x)}{\partial x},$$

or for short

$$\frac{\partial T}{\partial t} = -U \frac{\partial T}{\partial x}.$$


Since $T$ is a function of both $x$ and $t$, and this equation involves partial derivatives with respect to both of the independent variables, this is a **partial differential equation** (PDE). It describes how the function $T(t, x)$ changes continuously as a function both of time and space. 

Although there are some analytical methods to solve PDEs, often it's necessary to use numerical methods. Here we'll look at simple numerical methods to solve such equations.
"""

# ╔═╡ 2033364e-278c-11eb-2936-17598ce14a41
md"""
## Numerics for the advection equation
"""

# ╔═╡ e9a37908-278c-11eb-278e-9bd155f0cae6
md"""
Let's return to the version of the equation in which the value at the *following* time step is isolated:

$$T^{n+1}_i = T^{n}_i - \left( U \frac{\delta t}{\delta x} \right) (T^n_{i} - T^n_{i-1}).$$

In the last term on the right-hand side, we see that we require combinations of values of $T$ at the *same* time step from *different* places, with certain coefficients.
"""

# ╔═╡ bcf1ceca-f557-4d75-9058-bbaa58665fb7
md"""
There are many approaches to implementing this numerically. The simplest is to directly transcribe the equation for the $i$th entry of the vector.

Calling `T` the current vector, i.e. $\mathbf{T}^n := (T^n_i)_{i=1, \ldots, N_x}$, and `T′` the new vector at the next time step, we have the following basic expression:

	T′[i] = T[i] + δt * U * (T[i-1] - T[i]) / δx

But now we realise a problem: What should we do when $i=1$? This will try to access the index 0 of the vector `T`, which does not exist!
"""

# ╔═╡ 3736a25e-4dec-46ac-9bf6-9712e3d00e7a
md"""

### Boundary conditions

This illustrates the necessity of choosing **boundary conditions** that specify what happens at the edge of the domain.

For simplicity we will choose to use **periodic boundary conditions**. This is a convenient mathematical fiction that allows us to treat all cells as being on the same footing, by wrapping the system around a torus, so that cells $i=1$ and $i=N_x$ are neighbours.
"""

# ╔═╡ e542a8da-284e-11eb-3297-6bbbf052284b
md"""
We can then write this as follows, where we separate out the case $i=1$:
"""

# ╔═╡ b15f4f44-284b-11eb-37c5-ab0153f7fe92
function advection(T, δt, δx, U)
	N = length(T)
	T′ = similar(T)  # create new vector of the same length
	
	# bulk cells:
	for i in 2:N  
		T′[i] = T[i] - δt * U * (T[i] - T[i-1]) / δx
	end

	# boundary cells:
	T′[1] = T[1] - δt * U * (T[1] - T[N]) / δx   # periodic
	
	return T′
end

# ╔═╡ fcbec610-d9fc-4e41-8e76-729dbbc61d92
md"""
This performs a single time step of the advection equation; it takes in the current vector of $T$s and returns the new $T$s after the step.

Note that this is just like a step of the Euler method for solving ODEs, but where many spatial coordinates are updated at the same time. Effectively we are solving a system of coupled ODEs!
"""

# ╔═╡ af79e360-286e-11eb-2a4d-3d6d7564088c
δt = 0.001;

# ╔═╡ dce9e53a-28f4-11eb-070b-17e10779a38b
U = 0.2;

# ╔═╡ addab3e6-f189-41d6-badb-92f0323b6192
# assign colours to particles:

cs = map(xx) do x
	if -U * δ < x < 0
		1
	elseif 1 - (U * δ) < x < 1
		2
	else
		0
	end
end
	

# ╔═╡ f684dd94-f1c7-4f79-9776-3a06b8eec39b
begin
	plot([0, 1, 1, 0, 0], [0, 0, 1, 1, 0], series=:shape, alpha=0.5, fill=true, ratio=1, label=false, leg=false)
	
	new_xx = xx .+ U .* t
	
	scatter!(xx .+ U .* t, yy, ms=1.5, alpha=0.1, c=:gray)
	
	if show_particles
		scatter!(new_xx[cs .!= 0], yy[cs .!= 0], ms=1.5, alpha=0.5, c=cs[cs .!= 0])
	end
	
	plot!([-1.5, 2], [0, 0], c=:black)
	plot!([-1.5, 2], [1, 1], c=:black)

	
	xlims!(-2, 2)
	ylims!(-0.1, 1.1)
	
	as_svg(plot!(axis=true, yticks=[0, 1]))
end

# ╔═╡ 8c05e3cc-2858-11eb-1e1c-9781c30738c3
md"""
Unfortunately this does *not* behave as we expect: instead of preserving the shape of the profile over time, it is decaying. This is due to the way we are approximating. 

A better way to discretize the spatial derivative is using the following **centered difference**:

$$\frac{\partial T(t_n, x_i)}{\partial x} \simeq \frac{T^n_{i+1} - T^n_{i-1}}{2 \delta x}$$


"""

# ╔═╡ a29fecac-285a-11eb-14b0-9313f8994fbb
function advection2(T, δt, δx, U)
	N = length(T)
	T′ = similar(T)  # create new vector of the same length
	
	for i in 2:N-1
		T′[i] = T[i] - δt * U * (T[i+1] - T[i-1]) / (2δx)
	end

	# periodic boundary:
	T′[1] = T[1] - δt * U * (T[2] - T[N]) / (2δx)
	T′[N] = T[N] - δt * U * (T[1] - T[N-1]) / (2δx)

	return T′
end

# ╔═╡ c59388ea-286e-11eb-0f21-eb18e5ba516f
md"""
# Diffusion
"""

# ╔═╡ 3c944998-2888-11eb-087d-492b9d0ee32e
md"""
Another key physical process is **diffusion**. This models how temperature or mass spreads out from hot or high concentration regions towards regions where it is cold or where there is a low concentration.

## Physical mechanism: Random walks

The physical mechanism behind this is **random motion**: this is the continuous limit of equations describing the evolution of the probability distribution in space and time of a cloud of random walkers.

This is the same process that we studied in lecture 2.6.
Using our current notation, there we showed that the probability distribution of a cloud of random walkers satisfies the following time evolution:

$$p^{n+1}_i = \frac{1}{2}(p^n_{i-1} + p^n_{i+1})$$

If now we say that the walkers jump only with a certain probability, with a large probability to stay in the same place, and that these random walkers are the carriers of heat, then we get 

$$T^{n+1}_i = \kappa (T^n_{i-1} - 2 T^n_i + T^n_{i+1}).$$

Watch [this video](https://www.youtube.com/watch?v=a3V0BJLIo_c) from last semester's class to see Grant Sanderson explaining this.
"""

# ╔═╡ 6ac74e34-ed58-4903-8c53-82be13b6c21f
md"""
## Continuous limit: Heat equation PDE
"""

# ╔═╡ de42149c-85ce-4e73-8503-84f64a173cbb
md"""
Introducing $\delta x$ as the spatial discretisation, and $\delta t$ as the time step, we get 

$$T^{n+1}_i = \kappa \frac{\delta t}{\delta x^2}  (T^n_{i-1} - 2 T^n_i + T^n_{i+1}).$$

"""

# ╔═╡ ef42d541-74a1-433a-9773-5e6cca525350
md"""
The continuous limit is the following **heat equation** or **diffusion equation**:
"""

# ╔═╡ 6b7cea44-2888-11eb-0208-990860d6a152
md"""
$$\frac{\partial T}{\partial t} = \kappa \frac{\partial^2 T}{\partial x^2}.$$
"""

# ╔═╡ 83a1e1f5-0946-422c-83f4-d7a19e9c0789
md"""
Here, $\kappa$ is the **heat diffusivity**, which says how quickly heat spreads out. In the context of diffusion of mass the equivalent is the **diffusion coefficient**, $D$.
"""

# ╔═╡ 68db3372-2888-11eb-1b03-b5ebca4c2bd5
md"""
To obtain a numerical method to solve this equation, we again need to discretise this, in particular the second derivative. One possible discretisation is

$$\frac{\partial^2 T}{\partial x^2}(t_n, x_i) \simeq \frac{T^n_{i+1} - 2 T^n_i + T^n_{i-1}}{\delta x^2}.$$
"""

# ╔═╡ d6131ad0-2889-11eb-3085-15d17e33ee7a
md"""
This may again be transcribed directly into code:
"""

# ╔═╡ 630314bc-2868-11eb-1b93-b7b08a4b2887
function diffusion(T, δt, δx, D)
	N = length(T)
	T′ = similar(T)  # create new vector of the same length
	
	for i in 2:N-1
		T′[i] = T[i] + δt * D * (T[i+1] -2T[i] + T[i-1]) / (δx^2)
	end

	# periodic boundary:
	T′[1] = T[1] + δt * D * (T[2] - 2T[1] + T[N]) / (δx^2)
	T′[N] = T[N] + δt * D * (T[1] - 2T[N] + T[N-1]) / (δx^2)

	return T′
end

# ╔═╡ e63cfa84-2889-11eb-1ea2-51726645ddd9
md"""
# The advection--diffusion PDE
"""

# ╔═╡ eee3008e-2889-11eb-088a-73aff304e736
md"""
Finally we can combine both mechanisms, to describe a tracer that is both being advected at a constant speed and diffusing. This basically utilises the composition of the advection and diffusion functions:
"""

# ╔═╡ ffd2a838-2889-11eb-1a7c-b35992543b8a
function advection_diffusion(T, δt, δx, (U, D))
	temp = advection2(T, δt, δx, U)
	return diffusion(temp, δt, δx, D)
end

# ╔═╡ 575a5f3c-2780-11eb-2119-27a4114ceac5
md"""
# Function library
"""

# ╔═╡ 5a3eec86-2780-11eb-0341-39a5c343fc52
function temperature_heatmap(x, T)

	p = heatmap(x, [0.], collect(T'), 
			   clims=(-1., 1.), cbar=false, xticks=nothing, yticks=nothing)

	return p
end

# ╔═╡ 6de1859c-277f-11eb-1ead-8b4794832d59
begin
	p1 = plot(0:0.001:Lₓ, T₀, label="T₀", lw=3)
	scatter!(xs, T₀.(xs), label="sampled")
	scatter!(xs, zero.(xs), label="x nodes", alpha=0.5, ms=3)
	
	xlabel!("x")
	ylabel!("T₀")
	
	for x in xs
		plot!([ (x, 0), (x, T₀(x)) ], ls=:dash, c=:black, label="", alpha=0.5)
	end
	
	hline!([0], ls=:dash, lab=false)
	
	
	p2 = temperature_heatmap(xs, T₀.(xs))
	
	plot(p1, p2, layout = grid(2, 1, heights=[0.9, 0.1]))

end

# ╔═╡ 9187350a-2851-11eb-05f0-d3a6eef190fe
function evolve(method, xs, δt, U, t_final=10.0, f₀=T₀)
	
	T = f₀.(xs)  
	δx = xs[2] - xs[1]
	
	t = 0.0
	ts = [t]
	
	results = [T]
	
	while t < t_final
		T′ = method(T, δt, δx, U)  # new
		push!(results, T′)
		
		t += δt
		push!(ts, t)
		
		T = copy(T′)

	end
	
	return ts, results
end

# ╔═╡ 30006c82-695d-40b1-8ded-22d03c3bff41
tt, results = evolve(advection_diffusion, xs, δt, (UU, DD))

# ╔═╡ 6b2bfc73-d0a9-4a36-970d-c89149238284
md"""
time step = $(@bind n6 Slider(1:length(results), show_value=true))
"""

# ╔═╡ 02a893e4-2852-11eb-358a-371459191da7
ts, evolution = evolve(advection, xs, δt, U)

# ╔═╡ e6ae447e-2851-11eb-3fe1-096459167f2b
@bind n Slider(1:length(evolution), show_value=true)

# ╔═╡ 014e2530-2852-11eb-103f-1d647cb999b0
let
	p1 = plot(xs, evolution[n], m=:o, xlim=(0, 1), ylim=(-1.1, 1.1), title="t = $(round(ts[n], digits=2))", leg=false)

	p2 = temperature_heatmap(xs, evolution[n])
	
	plot(p1, p2, layout = grid(2, 1, heights=[0.9, 0.1]))
end



# ╔═╡ e42ec13e-285a-11eb-3cc0-7dc41ed5495b
ts2, evolution2 = evolve(advection2, xs, δt, 0.1)

# ╔═╡ f60a8b5e-285a-11eb-0d35-8daf23cf92ae
n2_slider = @bind n2 Slider(1:length(evolution2), show_value=true)

# ╔═╡ f1b5d130-285a-11eb-001c-67035925f43d
let
	p1 = plot(xs, evolution2[n2], m=:o, xlim=(0, 1), ylim=(-3.1, 3.1), title="t = $(round(ts2[n2], digits=2))", leg=false)
	
	p2 = temperature_heatmap(xs, evolution2[n2])
	
	plot(p1, p2, layout = grid(2, 1, heights=[0.9, 0.1]))
end


# ╔═╡ 121255d2-288a-11eb-1fa5-9db68af8c232
ts3, evolution3 = evolve(diffusion, xs, δt, 0.01)

# ╔═╡ 09bc3c40-288a-11eb-0339-59f0b70e03a3
@bind n3 Slider(1:length(evolution3), show_value=true)

# ╔═╡ 21eb19f7-467b-4995-be65-8dede4eb7ac1
let
	p1 = plot(xs, results[n6], m=:o, xlim=(0, 1), ylim=(-3.1, 3.1), title="t = $(round(ts3[n3], digits=2))", leg=false)
	p2 = temperature_heatmap(xs, results[n6])

	plot(p1, p2, layout = grid(2, 1, heights=[0.9, 0.1]), clim=(-1, 1))
end

# ╔═╡ 175d9902-288a-11eb-3700-390ccd1caa5b
let
	p1 = plot(xs, evolution3[n3], m=:o, xlim=(0, 1), ylim=(-3.1, 3.1), title="t = $(round(ts3[n3], digits=2))", leg=false)
	p2 = temperature_heatmap(xs, evolution3[n3])

	plot(p1, p2, layout = grid(2, 1, heights=[0.9, 0.1]), clim=(-1, 1))
end


# ╔═╡ f6fa3770-288d-11eb-32de-f95e03705791
ts5, evolution5 = evolve(advection_diffusion, xs, δt, (1.0, 0.01))

# ╔═╡ 6eb00a02-288d-11eb-354b-b56cf5a8380e
@bind n5 Slider(1:length(evolution5), show_value=true)

# ╔═╡ 65126bfc-288d-11eb-2bfc-493588365164
let
	p1 = plot(xs, evolution5[n5], m=:o, xlim=(0, 1), ylim=(-1.1, 1.1), title="t = $(round(ts3[n5], digits=2))", leg=false)
	p2 = temperature_heatmap(xs, evolution5[n5])

	plot(p1, p2, layout = grid(2, 1, heights=[0.9, 0.1]), clim=(-1, 1))
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Plots = "~1.40.5"
PlutoUI = "~0.7.48"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.4"
manifest_format = "2.0"
project_hash = "8375424efedfa98a71e7207942f229f8ddf759c5"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9e2a6b69137e6969bab0152632dcb3bc108c8bdd"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+1"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "a2f1c8c668c8e3cb4cca4e57a8efdb09067bb3fd"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.0+2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "b8fe8546d52ca154ac556809e10c75e6e7430ac8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.5"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "b5278586822443594ff615963b0c09755771b3e0"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.26.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.ColorVectorSpace.weakdeps]
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "362a287c3aa50601b0bc359053d5c2468f0e7ce0"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.11"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "b1c55339b7c6c350ee89f2c1604299660525b248"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.15.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "ea32b83ca4fefa1768dc84e504cc0a94fb1ab8d1"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.4.2"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "dcb08a0d93ec0b1cdc4af184b26b591e9695423a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.10"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c6317308b9dc757616f0b5cb379db10494443a7"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.2+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "466d45dc38e15794ec7d5d63ec03d776a9aff36e"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.4+1"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "db16beca600632c95fc8aca29890d83788dd8b23"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.96+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "5c1d8ae0efc6c2e7b1fc502cbe25def8f661b7bc"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.2+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1ed150b39aebcc805c26b93a8d0122c940f64ce2"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.14+0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "3f74912a156096bd8fdbef211eff66ab446e7297"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.4.0+0"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "p7zip_jll"]
git-tree-sha1 = "3e527447a45901ea392fe12120783ad6ec222803"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.73.6"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "182c478a179b267dd7a741b6f8f4c3e0803795d6"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.73.6+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "7c82e6a6cd34e9d935e9aa4051b66c6ff3af59ba"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.80.2+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "d1d712be3164d61d1fb98e7ce9bcbc6cc06b45ed"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.8"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "a53ebe394b71470c7f97c2e7e170d51df21b17af"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.7"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c84a835e1a09b289ffcd2271bf2a337bbdda6637"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.3+0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d986ce2d884d49126836ea94ed5bfb0f12679713"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "70c5da094887fd2cae843b8db33920bac4b6f07d"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.2+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "5b0d630f3020b82c0775a51d05895852f8506f50"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.4"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "9fd170c4bbfd8b935fdc5f8b7aa33532c991a673"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.11+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fbb1f2bef882392312feb1ede3615ddc1e9b99ed"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.49.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0c4f9c4f1a50d8f35048fa0532dabbadf702f81e"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.40.1+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "2da088d113af58221c52828a80378e16be7d037a"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.5.1+1"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5ee6203157c120d79034c748a2acba45b82b8807"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.40.1+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "a2d09619db4e765091ee5c6ffe8872849de0feea"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.28"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "c1dd6d7978c12545b4179fb6153b9250c96b0075"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.3"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a028ee3cb5641cccc4c24e90c36b0a4f7707bdf5"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.14+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "35621f10a7531bc8fa58f74610b1bfb70a3cfc6b"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.43.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "6e55c6841ce3411ccb3457ee52fc48cb698d6fb0"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.2.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "7b1a9df27f072ac4c9c7cbe5efb198489258d1f5"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.1"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "TOML", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "082f0c4b70c202c37784ce4bfbc33c9f437685bf"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.40.5"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "ab55ee1510ad2af0ff674dbcced5e94921f867a9"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.59"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "492601870742dcd38f233b23c3ec629628c1d724"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.7.1+1"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "5cf7606d6cef84b543b483848d4ae08ad9832b21"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.3"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "96612ac5365777520c3c5396314c8cf7408f436a"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.1"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "d95fe458f26209c66a187b1114df96fd70839efd"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.21.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "975c354fcd5f7e1ddcc1f1a23e6e091d99e99bc8"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.4"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "93f43ab61b16ddfb2fd3bb13b3ce241cafb0e6c9"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.31.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "d9717ce3518dc68a99e6b96300813760d887a01d"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.1+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "a54ee957f4c86b526460a720dbc882fa5edcbefc"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.41+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ac88fb95ae6447c8dda6a5503f3bafd496ae8632"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.4.6+0"

[[deps.Xorg_libICE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "326b4fea307b0b39892b3e85fa451692eda8d46c"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.1.1+0"

[[deps.Xorg_libSM_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libICE_jll"]
git-tree-sha1 = "3796722887072218eabafb494a13c963209754ce"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.4+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "d2d1a5c49fae4ba39983f63de6afcbea47194e85"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.6+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "47e45cd78224c53109495b3e324df0c37bb61fbe"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.11+0"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "bcd466676fef0878338c61e655629fa7bbc69d8e"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.0+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "730eeca102434283c50ccf7d1ecdadf521a765a4"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+0"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "330f955bc41bb8f5270a369c473fc4a5a4e4d3cb"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e678132f07ddb5bfa46857f0d7620fb9be675d3b"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.6+0"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a68c9655fbe6dfcab3d972808f1aafec151ce3f8"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.43.0+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3516a5630f741c9eecb3720b1ec9d8edc3ecc033"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1827acba325fdcdf1d2647fc8d5301dd9ba43a9d"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.9.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d7015d2e18a5fd9a4f47de711837e980519781a4"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.43+1"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9c304562909ab2bab0262639bd4f444d7bc2be37"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+1"
"""

# ╔═╡ Cell order:
# ╟─5648fa26-da0b-41d9-b13f-debd4e0485af
# ╠═e0c0dc94-277e-11eb-379e-83d064a93413
# ╟─00877a4a-277c-11eb-3ec0-e71e4094b404
# ╟─1b25b916-277c-11eb-0274-4b4fb946258d
# ╟─956f5104-277d-11eb-291d-1faef485a5aa
# ╟─b12e76db-1a18-465a-8955-dab29dfde611
# ╟─c14470f2-d8a4-4d34-8470-09842b2576a3
# ╟─30006c82-695d-40b1-8ded-22d03c3bff41
# ╟─b04a6f81-3ece-4521-b141-a2e416718948
# ╟─6b2bfc73-d0a9-4a36-970d-c89149238284
# ╟─21eb19f7-467b-4995-be65-8dede4eb7ac1
# ╟─36328b70-277d-11eb-02c7-2f854c1466cc
# ╟─42190984-277d-11eb-1ac2-7d84516c3269
# ╟─d2bed768-277e-11eb-32cf-41f1fedec3cb
# ╠═e6493da0-277e-11eb-22ff-29752652b576
# ╟─0d6271c0-286c-11eb-1c9c-3ba039b49d24
# ╠═f17f7734-277e-11eb-25cf-5f2ba2db5aa3
# ╠═fa327c08-286b-11eb-0032-2384998a42a8
# ╟─0db43be2-284c-11eb-2740-4379437fd70c
# ╟─468a0590-2780-11eb-045c-d1f468fc4e50
# ╠═6de1859c-277f-11eb-1ead-8b4794832d59
# ╟─af30a0d0-2781-11eb-0274-ab423205facb
# ╟─646bc32e-284c-11eb-2ce8-5f64b1a49534
# ╟─79ce4b10-284c-11eb-2258-2155f850171d
# ╟─2494daaa-2780-11eb-3084-2317924048ea
# ╟─29444ffe-2780-11eb-0875-095302b5d486
# ╟─1dcb9690-6436-49f0-880f-23490fe28ea4
# ╟─b63bb2e8-1d23-48fb-94b5-60d947465830
# ╠═e94a90c5-f2c1-4b5b-9946-7869ef7775a6
# ╠═dd87fc01-4bf0-44f6-a9f6-560e433754a0
# ╠═7ae9f5b8-10ea-42a7-aa01-0e04a7287c77
# ╟─addab3e6-f189-41d6-badb-92f0323b6192
# ╟─2f24e0c7-b05c-4f89-835a-081f8e6107e5
# ╟─75bc87be-2b66-46b5-8de8-428a63655815
# ╟─f684dd94-f1c7-4f79-9776-3a06b8eec39b
# ╟─3437e53b-9dd0-4afe-a1bd-a556871d1799
# ╟─65df7158-60dc-4809-82a3-913a79bcfc75
# ╟─7256778a-2785-11eb-0369-f3b43d5dd203
# ╟─44433a34-2782-11eb-0079-837c9306c5bd
# ╟─87e2be25-227c-498c-94fa-6e404c8918f1
# ╟─72c0ab0c-2781-11eb-1f59-9b22a52b0be0
# ╟─e5761990-278b-11eb-134e-7954b577b1ac
# ╟─2033364e-278c-11eb-2936-17598ce14a41
# ╟─e9a37908-278c-11eb-278e-9bd155f0cae6
# ╟─bcf1ceca-f557-4d75-9058-bbaa58665fb7
# ╟─3736a25e-4dec-46ac-9bf6-9712e3d00e7a
# ╟─e542a8da-284e-11eb-3297-6bbbf052284b
# ╠═b15f4f44-284b-11eb-37c5-ab0153f7fe92
# ╟─fcbec610-d9fc-4e41-8e76-729dbbc61d92
# ╠═af79e360-286e-11eb-2a4d-3d6d7564088c
# ╠═dce9e53a-28f4-11eb-070b-17e10779a38b
# ╠═02a893e4-2852-11eb-358a-371459191da7
# ╠═e6ae447e-2851-11eb-3fe1-096459167f2b
# ╟─014e2530-2852-11eb-103f-1d647cb999b0
# ╟─8c05e3cc-2858-11eb-1e1c-9781c30738c3
# ╠═a29fecac-285a-11eb-14b0-9313f8994fbb
# ╠═e42ec13e-285a-11eb-3cc0-7dc41ed5495b
# ╠═f60a8b5e-285a-11eb-0d35-8daf23cf92ae
# ╠═f1b5d130-285a-11eb-001c-67035925f43d
# ╟─c59388ea-286e-11eb-0f21-eb18e5ba516f
# ╟─3c944998-2888-11eb-087d-492b9d0ee32e
# ╟─6ac74e34-ed58-4903-8c53-82be13b6c21f
# ╟─de42149c-85ce-4e73-8503-84f64a173cbb
# ╟─ef42d541-74a1-433a-9773-5e6cca525350
# ╟─6b7cea44-2888-11eb-0208-990860d6a152
# ╟─83a1e1f5-0946-422c-83f4-d7a19e9c0789
# ╟─68db3372-2888-11eb-1b03-b5ebca4c2bd5
# ╟─d6131ad0-2889-11eb-3085-15d17e33ee7a
# ╠═630314bc-2868-11eb-1b93-b7b08a4b2887
# ╠═121255d2-288a-11eb-1fa5-9db68af8c232
# ╠═09bc3c40-288a-11eb-0339-59f0b70e03a3
# ╠═175d9902-288a-11eb-3700-390ccd1caa5b
# ╟─e63cfa84-2889-11eb-1ea2-51726645ddd9
# ╟─eee3008e-2889-11eb-088a-73aff304e736
# ╠═ffd2a838-2889-11eb-1a7c-b35992543b8a
# ╠═f6fa3770-288d-11eb-32de-f95e03705791
# ╠═6eb00a02-288d-11eb-354b-b56cf5a8380e
# ╠═65126bfc-288d-11eb-2bfc-493588365164
# ╟─575a5f3c-2780-11eb-2119-27a4114ceac5
# ╟─5a3eec86-2780-11eb-0341-39a5c343fc52
# ╠═9187350a-2851-11eb-05f0-d3a6eef190fe
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
