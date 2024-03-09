import React from "react";
import {
  Box,
  Flex,
  Spacer,
  Image,
  Text,
  Circle,
  Link,
  HStack,
} from "@chakra-ui/react";
import logo from "@/public/Assets/logo.png";

const Header = () => {
  return (
    <header style={{ width: "100%" }}>
      <Flex alignItems="center" padding={2}>
        <Box>
          <Image src={logo.src} alt="Logo" width={16} height={16} />{" "}
        </Box>
        <Box>
          <Text fontSize="36" fontWeight="bold">
            Social Briks
          </Text>
        </Box>
        <Spacer />
        <Spacer />
        <Box>
          <Flex alignItems="center">
            <Spacer />
            <HStack spacing={12}>
              <Link href="/option1">
                <Text fontSize={"l"} fontWeight={"bold"}>
                  Option 1
                </Text>
              </Link>
              <Link href="/option2">
                <Text fontSize={"l"} fontWeight={"bold"}>
                  Option 2
                </Text>
              </Link>
              <Link href="/option3">
                <Text fontSize={"l"} fontWeight={"bold"}>
                  Option 3
                </Text>
              </Link>
              <Link href="/profile">
                <Box>
                  <Circle size="40px" bg="blue.500" />
                </Box>
              </Link>
            </HStack>
          </Flex>
        </Box>
      </Flex>
      <Box borderBottom="1px solid black" width="100%" />
    </header>
  );
};

export default Header;
