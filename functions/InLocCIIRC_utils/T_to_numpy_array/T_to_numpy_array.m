function T_str = T_to_numpy_array(T)
    T_str = sprintf('np.reshape(np.array([%0.4f, %0.4f, %0.4f]), (3,1))', ...
                    T(1), T(2), T(3));
end