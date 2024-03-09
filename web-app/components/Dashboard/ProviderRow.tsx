import React from "react";
import { Tr, Td, Badge, Button } from "@chakra-ui/react";

const ProviderRow = () => {
  function getStatusColor(status: string) {
    switch (status) {
      case "Enabled":
        return "green";
      case "Not-Enabled":
        return "orange";
      default:
        return "red";
    }
  }

  return (
    <Tr>
      <Td textAlign={"center"}>1</Td>
      <Td textAlign={"center"}>20</Td>
      <Td textAlign={"center"}>30</Td>
      <Td textAlign={"center"}>30</Td>
      <Td textAlign={"center"}>
        <Badge colorScheme={getStatusColor("Enabled")}>{"Enabled"}</Badge>
      </Td>
      <Td textAlign={"center"}>30</Td>
      <Td textAlign={"center"}>
        {" "}
        <Button size={"sm"}>Contact</Button>{" "}
      </Td>
    </Tr>
  );
};

export default ProviderRow;
