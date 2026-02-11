import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async redirects() {
    return [
      {
        source: '/pipelines/:pipelineId',
        destination: '/projects/:pipelineId',
        permanent: true,
      },
      {
        source: '/pipelines/:pipelineId/review',
        destination: '/projects/:pipelineId/review',
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
