function [xk, H, g] = gmres_general(A, b, x0, max_iter, ...
    restart_value, error_tol, type, omega)
%% Approximate the solution to the linear system Ax = b using GMRES
% Approximate the solution to the linear system Ax = b using C iterations
% of the restarted Generalised Minimum Residual Method (GMRES) which 
% generates basis vectors using Arnoldi's method with Given's rotations.
%
%   Input:
%       A: a real nxn matrix.
%       b: a real nx1 vector.
%       x0: an approximation of the solution.
%       k: the number of vectors generated by the Arnoldi method each
%           iteration of the GMRES method.
%       max_iter: the maximum number of iterations of the GMRES method.
%       restart_value: the restart value for the arnoldi process.
%       error_tol: the error tolerance imposed on the residual for
%           pre-emptively stopping the Arnoldi iteration within the GMRES
%           method.
%
%   Output:
%       x: the solution vector.
%

% construct matrix preconditioner
diagonal_index = 0;

switch(type)
    case 'ilu'
        setup.type = 'nofill';
        setup.milu = 'row';
        setup.droptol = 0.1;
        [L,U] = ilu(A, setup);
    case 'jacobi'
        L = spdiags(diag(A), diagonal_index, speye(length(b)));
        U = speye(length(b));
    case 'sor'
        L = spdiags(diag(A) / omega, diagonal_index, tril(A));
        U = speye(length(b));
    case 'none'
        L = speye(length(b));
        U = L;
end

% initialise the current approximation of the solution
xk = x0;

% perform GMRES using the current approximation of the solution
i = 0;
residual = realmax;
while (residual > error_tol && i < max_iter)
    
    % initialise for the "first" Krylov subspace vector
    r0 = b - A * xk;
    
    % generate the orthonormal basis
    [Q, H, g] = arnoldi_general(A, L, U, r0, restart_value, error_tol);
    
    % compute the minimiser (least squares problem)
    y = H(1:end-1, :) \ g(1:end-1);

    % update the solution
    x_precond = L * U * xk + Q * y;
    xk = U \ (L \ x_precond);
    
    % update loop parameters
    residual = g(end);
    i = i + 1;
end
end
