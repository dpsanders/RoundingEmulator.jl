using Base.Math: ldexp

# Add
function add_up(a::T, b::T) where T<:FloatTypes
    x, y = Base.add12(a, b) # twosum
    if isinf(x)
        ifelse(x == typemin(x) && isfinite(a) && isfinite(b), -floatmax(x), x)
    else
        y > zero(y) ? nextfloat(x) : x
    end
end

# add_down
# rule for signed zero
# y = 0 -> x = a + b
# 1) x ≂̸ 0 => x
# 2) x = 0, a = -b ≂̸ 0 => -0.0
# 3) x = 0, a = b = 0
#    (a, b) = (0.0, 0.0) => 0.0
#    (a, b) = (-0.0, 0.0) => -0.0
#    (a, b) = (-0.0, -0.0) => -0.0
function add_down(a::T, b::T) where T<:FloatTypes
    x, y = Base.add12(a, b) # twosum
    if isinf(x)
        ifelse(x == typemax(x) && isfinite(a) && isfinite(b), floatmax(x), x)
    elseif y < zero(y)
        prevfloat(x)
    else
        ifelse(x == zero(x) && (signbit(a) || signbit(b)), -zero(x), x)
    end
end

# Sub
sub_up(a::T, b::T) where T<:FloatTypes = add_up(a, -b)
sub_down(a::T, b::T) where T<:FloatTypes = add_down(a, -b)

# const
for T in (Float32, Float64)
    # http://verifiedby.me/adiary/09
    @eval c_1(::Type{$T}) = $(ldexp(one(T), log2u(T) + 2 * precision(T) + 1))
    @eval c_2(::Type{$T}) = $(ldexp(one(T), ceil(Int, -log2u(T)//2)))
    @eval c_3(::Type{$T}) = $(ldexp(one(T), -log2u(T) - 3 * precision(T) + 3))
    @eval e_1(::Type{$T}) = $(2 * precision(T) - 1)
    @eval c_5(::Type{$T}) = $(ldexp(one(T), 2 * precision(T)))
    @eval c_6(::Type{$T}) = $(ldexp(one(T), precision(T)))
end

# Mul
# http://verifiedby.me/adiary/pub/kashi/image/201406/nas2014.pdf

function mul_up(a::T, b::T) where T<:FloatTypes
    x, y = Base.mul12(a, b)
    if isinf(x)
        ifelse(x == typemin(x) && isfinite(a) && isfinite(b), -floatmax(x), x)
    elseif abs(x) > c_1(T) # not zero(x): (a, b) = (-2.1634867667116802e-200, 1.6930929484402486e-119) fails
        y > zero(y) ? nextfloat(x) : x
    else
        mult = c_2(T)
        s, s2 = Base.mul12(a * mult, b * mult)
        t = (x * mult) * mult
        t < s || (t == s && s2 > zero(s2)) ? nextfloat(x) : x
    end
end

function mul_down(a::T, b::T) where T<:FloatTypes
    x, y = Base.mul12(a, b)
    if isinf(x)
        ifelse(x == typemax(x) && isfinite(a) && isfinite(b), floatmax(x), x)
    elseif abs(x) > c_1(T) # not zero(x): (a, b) = (6.640350825165134e-116, -1.1053488936824272e-202) fails
        y < zero(y) ? prevfloat(x) : x
    else
        mult = c_2(T)
        s, s2 = Base.mul12(a * mult, b * mult)
        t = (x * mult) * mult 
        t > s || (t == s && s2 < zero(s2)) ? prevfloat(x) : x
    end
end

# Div
function div_up(a::T, b::T) where T<:FloatTypes
    if iszero(a) || iszero(b) || isinf(a) || isinf(b) || isnan(a) || isnan(b)
        a / b
    else
        # if b < 0, flip sign of a and b
        a = flipsign(a, b)
        b = abs(b)
        if abs(a) < c_1(T)
            if abs(b) < c_3(T)
                a = ldexp(a, e_1(T))
                b = ldexp(b, e_1(T))
            else
                a < zero(a) ? zero(a) : nextfloat(zero(a))
            end
        end
        d = a / b
        x, y = Base.mul12(d, b)
        x < a || (x == a && y < zero(y)) ? nextfloat(d) : d
    end
end

function div_down(a::T, b::T) where T<:FloatTypes
    if iszero(a) || iszero(b) || isinf(a) || isinf(b) || isnan(a) || isnan(b)
        a / b
    else
        # if b < 0, flip sign of a and b
        a = flipsign(a, b)
        b = abs(b)
        if abs(a) < c_1(T)
            if abs(b) < c_3(T)
                a = ldexp(a, e_1(T))
                b = ldexp(b, e_1(T))
            else
                a < zero(a) ? prevfloat(zero(a)) : zero(a)
            end
        end
        d = a / b
        x, y = Base.mul12(d, b)
        x > a || (x == a && y > zero(y)) ? prevfloat(d) : d
    end
end

# Sqrt
function sqrt_up(a::FloatTypes)
    sqrt(a)
end

function sqrt_down(a::FloatTypes)
    sqrt(a)
end