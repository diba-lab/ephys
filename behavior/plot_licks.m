function [water_out, time_out, ha] = plot_licks(capture_file, water_in, time_in, ha)
% [water_out, time_out] = plot_licks(capture_file, water_in, time_in, ha)
%
% Plot licks versus time during water training

if nargin < 4
    figure; ha = gca;
end

data = importdata(capture_file);
water_out = [water_in, sum(data == 1) + sum(data ==3)];
time_out = [time_in now];

plot(ha, (time_out - time_out(1))*24*60*60, water_out, 'b-*')
xlabel( 'Time(s)');
ylabel('Water Deliveries');

end

