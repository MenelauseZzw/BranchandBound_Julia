#assignment1
#question 3
#author: Zhongwen Zhang
#email: zzhan896@uwo.ca

#(a)
@everywhere using JuMP
@everywhere using Clp

#Here is the function used to define the original problem we will solve
#We can just change the content of this function to make this algorithm
#adapted to solve other problems
@everywhere function getmodel()
  m = Model(solver = ClpSolver())
  @variable(m, x[1:2] >= 0)
  @objective(m,Max,x[2])
  @constraints(m, begin 
  -x[1]+x[2]<=1
  3x[1]+2x[2]<=12
  2x[1]+3x[2]<=12
  end)
  return m,x
end

#here I assume that firstsolve will have result  
@everywhere function firstsolve()
  m = getmodel()
  status = solve(m[1])
  v = getobjectivevalue(m[1])
  vars = m[2]
  lenv = length(vars)
  x=[]
  for i=1:lenv
    push!(x,getvalue(vars[i]))
  end
  return v,x
end

@everywhere function getresult(btr)
  s = solve(btr[1])
  if s == :Optimal
    objectivevalue = getobjectivevalue(btr[1])
    value = getvalue(btr[2])
    return s,objectivevalue,value
  else
    return s,-1
  end
end
  
@everywhere function isright(result)
  res = result
  len = length(res)
  flag = 0
  for i=1:len
    if res[i]==ceil(res[i])
	  flag = flag + 1
	else
	  break
	end
  end
  if(flag==len)
    return true
  else
    return false
	end
end

#construction of branch
@everywhere function contree(j,reso)
  res = reso[2]
  current = j
  level = 0
  while current != 0
    current = floor(current / 2)
	level += 1
  end
  m = getmodel()
  model = m[1]
  vars = m[2]
  len = length(vars)
  #println(len)
  level = level - 1 #determine the level of the tree
  #println(level)
  if level > length(vars)
	  temp = j
	  diff = level - len
	  while level != diff
		if(temp%2==0)
		  @constraint(model,vars[(level+1)%len+1]<=floor(res[(level+1)%len+1]))
		else
		  @constraint(model,vars[(level+1)%len+1]>=ceil(res[(level+1)%len+1]))
		end
		temp = floor(temp / 2)
		level = level - 1
	  end
   else
     temp = j
	  while level != 0
		if(temp%2==0)
		  @constraint(model,vars[level]<=floor(res[level]))
		else
		  @constraint(model,vars[level]>=ceil(res[level]))
		end
		temp = floor(temp / 2)
		level = level - 1
	  end
	end
      
  return j,m
end

@everywhere function BnB_p_max3()
  #construct active list
  np = nprocs()
  activelist = []
  #initialize the result
  res = firstsolve()
  Vopt=res[1]
  Xopt=res[2]
  len = length(Xopt)
  n = 3
  idx = 1
  if !isright(Xopt)
    push!(activelist,contree(2,res))
	push!(activelist,contree(3,res))
	idx += 2
	n += 4
	@sync begin
	  for p=1:np
	    if p != myid() || np == 1
		  @async begin
		    while true
			  if activelist != []
			    #println(activelist)
			    m = pop!(activelist)
				result = remotecall_fetch(getresult,p,m[2])
			    #println(result)
				if(result[1] != :Optimal)
				  n -= 2
				else
				  if isright(result[3])
				    if !isright(Xopt) || result[2]>=Vopt
				      Xopt = result[3]
					  Vopt = result[2]
					end
					n -= 2
				  elseif result[2]>=Vopt
				    push!(activelist,contree(2*m[1],result[2:3]))
					push!(activelist,contree(2*m[1]+1,result[2:3]))
					println(result)
					#println(activelist)
					idx += 2
					n += 4
				  else
				    n -= 2
				  end
				end
		      end
			  if idx == n && activelist==[]
			    break
			  end
			end
		  end
		end
	  end
	end
  else
    println("Integer solution at beginning")
	Vopt,Xopt
  end
  if isright(Xopt)
    println("Successfully found integer solution!")
    Vopt,Xopt
  else
    println("Do not have integer solution!")
  end
end

@everywhere function BnB_p_min3()
  #construct active list
  np = nprocs()
  activelist = []
  #initialize the result
  res = firstsolve()
  Vopt=res[1]
  Xopt=res[2]
  len = length(Xopt)
  n = 3
  idx = 1
  if !isright(Xopt)
    push!(activelist,contree(2,res))
	push!(activelist,contree(3,res))
	idx += 2
	n += 4
	@sync begin
	  for p=1:np
	    if p != myid() || np == 1
		  @async begin
		    while true
			  if activelist != []
			    #println(activelist)
			    m = pop!(activelist)
				result = remotecall_fetch(getresult,p,m[2])
			    #println(result)
				if(result[1] != :Optimal)
				  n -= 2
				else
				  if isright(result[3])
				    if !isright(Xopt) || result[2]<=Vopt
				      Xopt = result[3]
					  Vopt = result[2]
					end
					n -= 2
				  elseif result[2]<=Vopt
				    push!(activelist,contree(2*m[1],result[2:3]))
					push!(activelist,contree(2*m[1]+1,result[2:3]))
					println(result)
					#println(activelist)
					idx += 2
					n += 4
				  else
				    n -= 2
				  end
				end
		      end
			  if idx == n && activelist==[]
			    break
			  end
			end
		  end
		end
	  end
	end
  else
    println("Integer solution at beginning")
	Vopt,Xopt
  end
  if isright(Xopt)
    println("Successfully found integer solution!")
    Vopt,Xopt
  else
    println("Do not have integer solution!")
  end
end

BnB_p_max3()

#(b)
@everywhere function getmodel()
  m = Model(solver = ClpSolver())
  @variable(m, 0<= x[1:12] <= 1)
  @objective(m,Min,sum(x[i] for i=1:11))
  @constraints(m, begin 
  x[1] +x[2]+x[3]+x[4] >=1
  x[1]+x[2]+x[3]+x[5]>=1
  x[1]+x[2]+x[3]+x[5]+x[4]+x[6]>=1
  x[1]+x[4]+x[3]+x[6]+x[7]>=1
  x[2]+x[3]+x[5]+x[6]+x[8]+x[9]>=1
  x[3]+x[4]+x[5]+x[6]+x[7]+x[8]>=1
  x[4]+x[6]+x[7]+x[8]>=1
  x[5]+x[6]+x[7]+x[8]+x[9]+x[10]>=1
  x[5]+x[8]+x[9]+x[10]+x[11]>=1
  x[8]+x[9]+x[10]+x[11]>=1
  x[9]+x[10]+x[11]>=1
  end)
  return m,x
 end
BnB_p_min3()

@everywhere function getmodel()
  m = Model(solver = ClpSolver())
  @variable(m, x[1:2] >= 0)
  @objective(m,Max,100x[1]+150x[2])
  @constraints(m, begin 
  8000x[1]+4000x[2]<=40000
  15x[1]+30x[2] <=200
  end)
  return m,x
 end
BnB_p_max3()

@everywhere function getmodel()
  m = Model(solver = ClpSolver())
  @variable(m, x[1:2] >= 0)
  @objective(m,Max,x[1]+5x[2])
  @constraints(m, begin 
  x[1]+10x[2]<=20
  x[1] <=2
  end)
  return m,x
 end
BnB_p_max3()

@everywhere function getmodel()
  m = Model(solver = ClpSolver())
  @variable(m, x[1:2] >= 0)
  @objective(m,Max,x[1]+4x[2])
  @constraints(m, begin 
  2x[1]+4x[2]<=7
  10x[1]+3x[2]<=14
  end)
  return m,x
 end
BnB_p_max3()

@everywhere function getmodel()
  m = Model(solver = ClpSolver())
  @variable(m, x[1:2] >= 0)
  @objective(m,Max,3x[1]+4x[2])
  @constraints(m, begin
  2x[1]+5x[2]<=15
  2x[1]-2x[2]<=5
  end)
  return m,x
end
BnB_p_max3()

@everywhere function getmodel()
  m = Model(solver = ClpSolver())
  @variable(m, 0<=x[1:6] <=1)
  @objective(m,Min,sum(x[i] for i=1:6))
  @constraints(m, begin 
  x[1]+x[2]>=1
  x[1]+x[2]+x[6]>=1
  x[3]+x[4]>=1
  x[3]+x[4]+x[5]>=1
  x[4]+x[5]+x[6]>=1
  x[2]+x[5]+x[6]>=1
  end)
  return m,x
end
BnB_p_min3()