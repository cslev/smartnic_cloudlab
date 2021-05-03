"""Bluefield2 - This topology uses two Bluefield2 enabled hosts @ Clemson. They are connected back to back with 3 links; 2 of them forced to be 40G to enforce SmartNIC connectivity. The other link is only required as a common 1G interfaces have the machines connected normally, too"""

#
# NOTE: This code was machine converted. An actual human would not
#       write code like this!
#

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg
# Import the Emulab specific extensions.
import geni.rspec.emulab as emulab

# Create a portal object,
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()
rspec = pg.Request()


#### ---------------------------- TOPOLOGY -------------------------------------
# Node bf1
node_bf1 = request.RawPC('bf1')
node_bf1.hardware_type = 'r7525'
node_bf1.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU20-64-STD'
bs1 = node_bf1.Blockstore("bs1", "/mydata")
bs1.size = "50GB"
iface0 = node_bf1.addInterface('interface-0', pg.IPv4Address('10.0.0.1','255.255.255.0'))
iface1 = node_bf1.addInterface('interface-2', pg.IPv4Address('10.0.1.1','255.255.255.0'))
iface2 = node_bf1.addInterface('interface-4', pg.IPv4Address('10.10.10.1','255.255.255.0'))


# Node bf2
node_bf2 = request.RawPC('bf2')
node_bf2.hardware_type = 'r7525'
node_bf2.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU20-64-STD'
bs2 = node_bf2.Blockstore("bs2", "/mydata")
bs2.size = "50GB"
iface4 = node_bf2.addInterface('interface-1', pg.IPv4Address('10.0.0.2','255.255.255.0'))
iface5 = node_bf2.addInterface('interface-3', pg.IPv4Address('10.0.1.2','255.255.255.0'))
iface6 = node_bf2.addInterface('interface-5', pg.IPv4Address('10.10.10.2','255.255.255.0'))

# Link link-0
link_0 = request.Link('link-0')
link_0.Site('undefined')
iface4.bandwidth = 40000000
link_0.addInterface(iface4)
iface0.bandwidth = 40000000
link_0.addInterface(iface0)

# Link link-1
link_1 = request.Link('link-1')
link_1.Site('undefined')
iface1.bandwidth = 40000000
link_1.addInterface(iface1)
iface5.bandwidth = 40000000
link_1.addInterface(iface5)

# Link link-2
link_2 = request.Link('link-2')
link_2.Site('undefined')
iface2.bandwidth = 1000000
link_2.addInterface(iface2)
iface6.bandwidth = 1000000
link_2.addInterface(iface6)
#### ========================= END TOPOLOGY ====================================

#### ------------------------- CONFIGURE NODES ---------------------------------
node_bf1.addService(pg.Execute(shell="bash", command="/local/repository/smartnic_bootstap.sh"))
node_bf2.addService(pg.Execute(shell="bash", command="/local/repository/smartnic_bootstap.sh"))

rspec.addResource(node_bf1)
rspec.addResource(node_bf2)

# Print the generated rspec
pc.printRequestRSpec(rspec)
