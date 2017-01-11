# frozen_string_literal: true
require "pharos/kubernetes"

# NodesController is responsible for everything related to nodes: showing
# information on nodes, deleting them, etc.
class NodesController < ApplicationController
  def index
    kube   = Pharos::Kubernetes.new
    @nodes = kube.client.get_nodes
  end

  def show
    kube  = Pharos::Kubernetes.new
    @node = kube.client.get_node(params[:id])
  end

  def destroy
    kube = Pharos::Kubernetes.new
    kube.client.delete_node(params[:id])
    redirect_to nodes_path
  end
end
