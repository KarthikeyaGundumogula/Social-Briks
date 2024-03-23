import React from "react";
import {
  Box,
  Badge,
  Image,
  Text,
  HStack,
  Heading,
  Grid,
  GridItem,
} from "@chakra-ui/react";
import { motion } from "framer-motion";

interface AppCardProps {
  title: string;
  options: string[];
  status: string;
}

const AppCard: React.FC<AppCardProps> = ({ title, options, status }) => {
  const logo = `https://picsum.photos/seed/${encodeURIComponent(
    title
  )}/200/300`;
  return (
    <>
      <Box
        borderWidth="1px"
        borderRadius="12"
        p={2}
        width="400px"
        height="150px"
        bg={"AppWorkspace"}
        _hover={{
          cursor: "pointer",
          boxShadow: "2xl",
          width: "420px",
          height: "160px",
        }}
      >
        {" "}
        <Badge
          position="relative"
          top={1}
          left={"95%"}
          variant="solid"
          width={4}
          height={4}
          borderRadius={100}
          textAlign={"center"}
          colorScheme={status === "active" ? "green" : "red"}
        />
        <Grid
          height={100}
          templateRows="repeat(2, 1fr)"
          templateColumns="repeat(5, 1fr)"
          gap={4}
        >
          <GridItem rowSpan={2} colSpan={1}>
            <Image src={logo} alt="App Logo" borderRadius={12} />
          </GridItem>
          <GridItem colSpan={4}>
            <Heading size={"lg"} fontWeight="bold">
              {title}
            </Heading>
          </GridItem>
          <GridItem colSpan={4}>
            <HStack>
              {options.map((option, index) => (
                <Box key={index}>
                  <HStack>
                    <Text>{"**"}</Text>
                    <Text fontWeight="bold">{option}</Text>
                  </HStack>
                </Box>
              ))}
            </HStack>
          </GridItem>
        </Grid>
      </Box>
    </>
  );
};

export default AppCard;
