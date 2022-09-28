import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt
from mpl_toolkits import mplot3d
import itertools
import sys

def p3p_distances(d12, d23, d31, c12, c23, c31):
    a0, a1, a2, a3, a4 = p3p_polynom(d12, d23, d31, c12, c23, c31)
    C = np.array([[0, 0, 0, -a0/a4], [1, 0, 0, -a1/a4], [0, 1, 0, -a2/a4], [0, 0, 1, -a3/a4]])
    w, v = np.linalg.eig(C)
    wReal = list(map(lambda _: _.real, filter(lambda _: _.imag == 0.0, w)))
    N1 = []
    N2 = []
    N3 = []
    for n12 in wReal:
        m1 = d12**2
        p1 = -2*d12**2*n12*c23
        q1 = d23**2*(1+n12**2-2*n12*c12)-d12**2*n12**2
        m2 = d31**2-d23**2
        p2 = 2*d23**2*c31-2*d31**2*n12*c23
        q2 = d23**2-d31**2*n12**2
        n13 = (m1*q2-m2*q1) / (m1*p2-m2*p1)
        n1 = d12/np.sqrt(1+n12**2-2*n12*c12)
        n2 = n1*n12
        n3 = n1*n13
        N1.append(n1)
        N2.append(n2)
        N3.append(n3)
    E = p3p_dverify(N1, N2, N3, d12, d23, d31, c12, c23, c31)
    lowError = list(filter(lambda i: int(np.all(E[i,:] < 1e-4)), range(len(N1))))
    N1 = [N1[i] for i in lowError]
    N2 = [N2[i] for i in lowError]
    N3 = [N3[i] for i in lowError]
    if len(N1) == 1:
        N1 = N1[0]
        N2 = N2[0]
        N3 = N3[0]
    return N1, N2, N3

def p3p_polynom(d12, d23, d31, c12, c23, c31):
    a4 = -4*d23**4*d12**2*d31**2*c23**2+d23**8-2*d23**6*d12**2-2*d23**6*d31**2+d23**4*d12**4+2*d23**4*d12**2*d31**2+d23**4*d31**4
    a3 = 8*d23**4*d12**2*d31**2*c12*c23**2+4*d23**6*d12**2*c31*c23-4*d23**4*d12**4*c31*c23+4*d23**4*d12**2*d31**2*c31*c23-4*d23**8*c12+4*d23**6*d12**2*c12+8*d23**6*d31**2*c12-4*d23**4*d12**2*d31**2*c12-4*d23**4*d31**4*c12
    a2 = -8*d23**6*d12**2*c31*c12*c23-8*d23**4*d12**2*d31**2*c31*c12*c23+4*d23**8*c12**2-4*d23**6*d12**2*c31**2-8*d23**6*d31**2*c12**2+4*d23**4*d12**4*c31**2+4*d23**4*d12**4*c23**2-4*d23**4*d12**2*d31**2*c23**2+4*d23**4*d31**4*c12**2+2*d23**8-4*d23**6*d31**2-2*d23**4*d12**4+2*d23**4*d31**4
    a1 = 8*d23**6*d12**2*c31**2*c12+4*d23**6*d12**2*c31*c23-4*d23**4*d12**4*c31*c23+4*d23**4*d12**2*d31**2*c31*c23-4*d23**8*c12-4*d23**6*d12**2*c12+8*d23**6*d31**2*c12+4*d23**4*d12**2*d31**2*c12-4*d23**4*d31**4*c12
    a0 = -4*d23**6*d12**2*c31**2+d23**8-2*d23**4*d12**2*d31**2+2*d23**6*d12**2+d23**4*d31**4+d23**4*d12**4-2*d23**6*d31**2
    return a0, a1, a2, a3, a4

def p3p_dverify(N1, N2, N3, d12, d23, d31, c12, c23, c31):
    E = np.zeros((len(N1), 3))
    for i in range(len(N1)):
        E[i,0] = p3p_dverifyOne(N1[i], N2[i], c12, d12)
        E[i,1] = p3p_dverifyOne(N2[i], N3[i], c23, d23)
        E[i,2] = p3p_dverifyOne(N3[i], N1[i], c31, d31)
    return E

def p3p_dverifyOne(n1, n2, c12, d12):
    return (np.sqrt(n1**2+n2**2-2*n1*n2*c12)-d12)/d12

# x: position vectors are columns
def project(x, P):
    x2 = np.vstack([x, np.ones((1,x.shape[1]))])
    projected = np.matmul(P, x2)
    projected = projected / projected[2,:]
    projected = projected[0:2,:]
    return projected

def buildProjectionMatrix(f, K, R, C):
    return f * np.hstack((K @ R, K @ (R @ -C)))

def cosine(x1beta, x2beta, K):
    top = x1beta.T @ (np.linalg.inv(K).T @ (np.linalg.inv(K) @ x2beta))
    bottom = np.linalg.norm(np.linalg.inv(K) @ x1beta) * np.linalg.norm(np.linalg.inv(K) @ x2beta)
    return top / bottom

def normalize(vec):
    return vec / np.linalg.norm(vec)

def to3by1vector(vec):
    return np.reshape(vec, (3,1))

def p3p_RC(N, u, X, K):
    uBeta = np.vstack([u, np.ones((1,u.shape[1]))])
    uGamma = np.linalg.inv(K) @ uBeta
    uGammaNorm = np.linalg.norm(uGamma, axis=0)
    Ns = np.tile(N, (3,1))
    uGammaNorms = np.tile(uGammaNorm, (3,1))
    Yeps = np.multiply(Ns, np.divide(uGamma, uGammaNorms))
    Z2eps = normalize(Yeps[:,1] - Yeps[:,0])
    Z3eps = normalize(Yeps[:,2] - Yeps[:,0])
    Z1eps = normalize(np.cross(Z2eps, Z3eps))
    Z2eps = normalize(np.cross(Z1eps, Z3eps))
    Z2delta = normalize(X[:,1] - X[:,0])
    Z3delta = normalize(X[:,2] - X[:,0])
    Z1delta = normalize(np.cross(Z2delta, Z3delta))
    Z2delta = normalize(np.cross(Z1delta, Z3delta))
    Zeps = list(map(lambda x: to3by1vector(x), [Z1eps, Z2eps, Z3eps]))
    Zeps = np.hstack(Zeps)
    Zdelta = list(map(lambda x: to3by1vector(x), [Z1delta, Z2delta, Z3delta]))
    Zdelta = np.hstack(Zdelta)
    R = Zeps @ np.linalg.inv(Zdelta)
    Cdelta = X[:,0] - (R.T @ Yeps[:,0])
    Cdelta = np.reshape(Cdelta, (3,1))
    return R, Cdelta

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: python3 reconstructPose.py <input path> <output path>')
        exit(1)
    inputPath = sys.argv[1]
    outputPath = sys.argv[2]

    inputData = sio.loadmat(inputPath, squeeze_me=True)
    u = inputData['u']
    x = inputData['x']
    K = inputData['K']
    k = 3
    IX = range(0,u.shape[1])
    iter = itertools.combinations(IX, k)
    lowestError = np.inf
    err_max = []
    Rs = []
    Cs = []
    for idx in iter:
        Xdelta = np.zeros((3,k), dtype=np.float)
        Xalpha = np.zeros((2,k), dtype=np.float)
        for i in range(k):
            Xdelta[:,i] = x[:,idx[i]]
            Xalpha[:,i] = u[:,idx[i]]
        Xbeta = np.vstack([Xalpha, np.ones((1,Xalpha.shape[1]))])
        c12 = cosine(Xbeta[:,0], Xbeta[:,1], K)
        c23 = cosine(Xbeta[:,1], Xbeta[:,2], K)
        c31 = cosine(Xbeta[:,2], Xbeta[:,0], K)
        d12 = np.linalg.norm(Xdelta[:,0] - Xdelta[:,1])
        d23 = np.linalg.norm(Xdelta[:,1] - Xdelta[:,2])
        d31 = np.linalg.norm(Xdelta[:,2] - Xdelta[:,0])
        N1, N2, N3 = p3p_distances(d12, d23, d31, c12, c23, c31)
        for i in range(len(N1)):
            N = np.array([N1[i], N2[i], N3[i]])
            R, C = p3p_RC(N, Xalpha, Xdelta, K)
            f = 1 # f is already included in K (camera with square pixels)
            P = buildProjectionMatrix(f, K, R, C)
            reprojected = project(x, P)
            distance = np.linalg.norm(u-reprojected, axis=0)
            maxDistance = np.max(distance)
            err_max.append(maxDistance)
            Rs.append(R)
            Cs.append(C)
            if maxDistance < lowestError:
                lowestError = maxDistance
                optimalR = R
                optimalC = C
                optimalP = P
                points_sel = np.array(idx)
                err_points = reprojected - u
    Rs = np.stack(Rs)
    Cs = np.stack(Cs)
    sio.savemat(outputPath, {'Rs': Rs, 'Cs': Cs, 'errors': err_max})