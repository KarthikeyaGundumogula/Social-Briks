import {
  Box,
  Button,
  FormControl,
  FormErrorMessage,
  FormLabel,
  Input,
  VStack,
} from "@chakra-ui/react";

const RegisterForm = () => {
  const onSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    // Handle form submission here
  };

  return (
    <Box
      width="100%"
      height="100vh"
      display="flex"
      justifyContent="center"
      alignItems="center"
      bg="white" // Set the background color of the page
    >
      <form>
        <VStack
          borderRadius={12}
          p={8}
          width={500}
          spacing={4}
          bg="whitesmoke" // Set the background color of the form container
          boxShadow="0px 0px 10px rgba(255, 255, 255, 0.5)" // Add a box shadow to create a different level of white color
        >
          {/* Field 1 */}
          <FormControl isRequired>
            <FormLabel htmlFor="field1">Field 1</FormLabel>
            <Input id="field1" required />
          </FormControl>

          {/* Field 2 */}
          <FormControl isRequired>
            <FormLabel htmlFor="field2">Field 2</FormLabel>
            <Input id="field2" required />
          </FormControl>

          {/* Field 3 */}
          <FormControl isRequired>
            <FormLabel htmlFor="field3">Field 3</FormLabel>
            <Input id="field3" required />
          </FormControl>

          {/* Field 4 */}
          <FormControl isRequired>
            <FormLabel htmlFor="field4">Field 4</FormLabel>
            <Input id="field4" required />
          </FormControl>

          <Button type="submit" colorScheme="facebook">
            Submit
          </Button>
        </VStack>
      </form>
    </Box>
  );
};

export default RegisterForm;
