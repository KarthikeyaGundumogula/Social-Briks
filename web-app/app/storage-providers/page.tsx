import {
  Box,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  TableContainer,
} from "@chakra-ui/react";
import Header from "@/components/Header";
import ProviderRow from "@/components/Dashboard/ProviderRow";

const TableComponent = () => {
  return (
    <>
      <Header />
      <Box m={10}>
        <TableContainer>
          <Table alignItems="center" variant="simple">
            <Thead color={"#070F2B"}>
              <Tr>
                <Th fontSize={20} color={"#060F2B"} textAlign={"center"}>
                  Address
                </Th>
                <Th fontSize={20} textAlign={"center"} color={"#060F2B"}>
                  Storage-Power
                </Th>
                <Th fontSize={20} textAlign={"center"} color={"#060F2B"}>
                  Sector-Size
                </Th>
                <Th fontSize={20} textAlign={"center"} color={"#060F2B"}>
                  Retrieval-Rate
                  <div style={{ fontSize: 12, marginLeft: 5 }}>(req/sec)</div>
                </Th>
                <Th fontSize={20} textAlign={"center"} color={"#060F2B"}>
                  Verified-Deals
                </Th>
                <Th fontSize={20} textAlign={"center"} color={"#060F2B"}>
                  Cost
                  <div style={{ fontSize: 12, marginLeft: 5 }}>(/epoch)</div>
                </Th>
                <Th fontSize={20} textAlign={"center"} color={"#060F2B"}>
                  Contact
                </Th>
              </Tr>
            </Thead>
            <Tbody>
              <ProviderRow />
              <ProviderRow />
              <ProviderRow />
              <ProviderRow />
              <ProviderRow />
              <ProviderRow />
            </Tbody>
          </Table>
        </TableContainer>
      </Box>
    </>
  );
};

export default TableComponent;
