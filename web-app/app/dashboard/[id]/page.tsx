import React from "react";
import Header from "@/components/Header";
import { Center, Heading } from "@chakra-ui/react";

const Dashboard: React.FC = () => {
  return (
    <div>
      <Header />
      <Center h="100vh">
        <Heading>Fuck you Canada</Heading>
      </Center>
    </div>
  );
};

export default Dashboard;
