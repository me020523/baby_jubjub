#https://www.heise.de/netze/rfc/rfcs/rfc7748.shtml
import sys
import pdb

def findCurve(prime, curveCofactor, twistCofactor, _A):
   F = GF(prime)
   A = _A
   while A < _A + 100000: 
     print(A)
     if (A-2.) % 4 != 0:
       A+=1.
       continue
     try:
       E = EllipticCurve(F, [0, A, 0, 1, 0])
     except:
       A+=1.
       continue
     groupOrder = E.order()
     if (groupOrder % curveCofactor != 0 or not is_prime(groupOrder // curveCofactor)):
       A+=1
       continue

     twistOrder = 2*(prime+1)-groupOrder
     if (twistOrder % twistCofactor != 0 or not is_prime(twistOrder // twistCofactor)):
       A+=1
       continue    
     return E, A, 1, groupOrder, curveCofactor, groupOrder // curveCofactor

def find1Mod4(prime, curveCofactor, twistCofactor, A):
   assert((prime % 4) == 1)
   return findCurve(prime, curveCofactor, twistCofactor, A)

def listGenPoint(prime, A, EC, N, h):
   F = GF(prime)
   for uInt in range(1, 1000):
      u = F(uInt)
      v2 = u^3 + A*u^2 + u
      if not v2.is_square():
         continue
         
      v = v2.sqrt()
      point = EC(u, v)
      pointOrder = point.order()
      if pointOrder != N:
         continue
      # find that generator point on the edwards curve
      (u_gen, v_gen, w_gen) = point
      gen_x, gen_y = mont_to_ted(u_gen, v_gen, prime)
      # make sure the generator point is on the twisted edwards curve
      assert(isOnEd(gen_x, gen_y, prime, a , d))
      # go back to montgomery
      u , v = ted_to_mont(gen_x, gen_y, prime)
      # confirm we are back where we started from
      assert (u == u_gen)
      assert (v == v_gen)

      # get base point on montgorery curve by multiplying the generator point by h
      base_x , base_y, base_z = h*EC(u_gen, v_gen)
      # find the same points on twisted edwards curve
      base_x , base_y = mont_to_ted(base_x , base_y, prime)

      # the generator is on the twisted edwards curve
      assert(isOnEd(base_x,base_y, prime , a , d))

      # print ("generator :" , gen_x, gen_y)
      print ("base :", base_x, base_y)
      print("=================================")

def mont_to_ted(u, v , r):
    x = Mod(u / v, r) 
    y = Mod((u-1)/(u+1), r) 
    return(x, y)

def ted_to_mont(x, y , r):
    u = Mod((1 + y )/ ( 1 - y)  , r)
    v = Mod((1 + y ) / ( (1 - y) * x) , r ) 
    return(u,v)

def isOnEd(x,y,r,a,d):
    return Mod(Mod(a,r)*(x**2),r) + Mod(y**2 , r) - 1 - Mod(d,r)*(Mod(x**2,r))*(Mod(y**2,r)) == 0 

prime = 21888242871839275222246405745257275088548364400416034343698204186575808495617
Fr = GF(prime)
h = 8 # cofactor

A = int(sys.argv[1])
EC, A, B, n, h , l = find1Mod4(prime, h, 4, A)

# A = 170214 another candidate
a = (A + 2) / B
d = (A - 2) / B

print("a " , a , "d " , d , sqrt(d))
# check we have a safe twist
assert(not d.is_square())
assert(a*d*(a-d)!=0)

print ("l : " , l)
print (factor(EC.quadratic_twist().order()))

# list generator point
listGenPoint(prime, A, EC, n, h)