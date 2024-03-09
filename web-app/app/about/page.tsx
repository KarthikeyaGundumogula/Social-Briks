import React from "react";
import Header from "@/components/Header";
import { Heading } from "@chakra-ui/react";

const About: React.FC = () => {
  return (
    <div>
      <Header />
      <Heading as="h1" textAlign="center">
        Fuck you Canada
      </Heading>
    </div>
  );
};

export default About;
