import React from "react";
import Header from "@/components/Header";
import { Box, Center, Grid, Heading } from "@chakra-ui/react";
import AppCard from "@/components/Dashboard/AppCard";

const Dashboard: React.FC = () => {
  return (
    <div>
      <Header />
      <Box padding={2} paddingLeft={8}>
        <Heading size="lg" textDecoration="underline">
          Applications
        </Heading>
      </Box>
      <Box alignItems="center" padding={2} paddingLeft={8}>
        <Grid templateColumns="repeat(3, 2fr)" gap={4}>
          <AppCard
            title="Social Briks"
            options={["red", "blue", "white", "fuck"]}
            status="active"
          />
          <AppCard
            title="Social Briks"
            options={["red", "blue", "white", "fuck"]}
            status="dead"
          />
          <AppCard
            title="Social Briks"
            options={["red", "blue", "white", "fuck"]}
            status="active"
          />
          <AppCard
            title="Social Briks"
            options={["red", "blue", "white", "fuck"]}
            status="active"
          />
        </Grid>
      </Box>
    </div>
  );
};

export default Dashboard;
