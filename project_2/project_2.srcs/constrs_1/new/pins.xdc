# 1. 允许时钟走普通引脚
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets i_clk_IBUF]

# 2. 【核心大招】强制让综合和优化器不准碰顶层模块里的任何逻辑
# 这条指令会保护你所有的 mac_u 实例和内部连线，不被 opt_design 优化掉
set_property DONT_TOUCH true [get_cells -hierarchical *]

# 3. 虚拟占位，给核心引脚随便落个脚点
set_property PACKAGE_PIN A1 [get_ports i_clk]
set_property PACKAGE_PIN B1 [get_ports i_rst_n]
set_property PACKAGE_PIN C1 [get_ports {i_data[0]}]
set_property PACKAGE_PIN D1 [get_ports {o_data[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports i_clk]
set_property IOSTANDARD LVCMOS33 [get_ports i_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports {i_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {o_data[0]}]

# 4. 允许剩下的 70 多个 m_out 引脚自动浮动布局
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property IOSTANDARD LVCMOS33 [get_ports *]